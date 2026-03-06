import Foundation
import AppKit
import os

@Observable
final class ProcessMonitor {
    // MARK: - Observable State
    var processes: [LucidProcess] = []
    var stats: SystemStats = SystemStats(
        cpuUsage: 0,
        memoryUsage: 0,
        memoryBytes: 0,
        totalMemoryBytes: 0,
        timestamp: Date()
    )
    var isRunning = false
    var lastError: String?
    var selectedFilter: FilterCategory = .all
    var filterCounts = FilterCounts()
    var activePorts: [UInt16] = []

    struct FilterCounts {
        var total: Int = 0
        var system: Int = 0
        var user: Int = 0
        var unknown: Int = 0
    }

    // MARK: - Private State
    private var timer: DispatchSourceTimer?
    private var previousCPUTimes: [pid_t: UInt64] = [:]
    private var previousCPUHistory: [Double] = []
    private var previousMemoryHistory: [Double] = []
    private let pollInterval: TimeInterval = 2.0
    private let logger = Logger(subsystem: "com.tan.lucid", category: "ProcessMonitor")
    private let timerQueue = DispatchQueue(label: "com.tan.lucid.timer", qos: .userInitiated)

    // Thread-safe refresh guard
    private let refreshLock = NSLock()
    private var _isRefreshing = false
    private var isRefreshing: Bool {
        get { refreshLock.withLock { _isRefreshing } }
        set { refreshLock.withLock { _isRefreshing = newValue } }
    }

    // LLM service for process identification
    private let llmService = LLMService()

    // Cached NSWorkspace app names (refreshed every other cycle)
    private var appNameCache: [pid_t: String] = [:]
    private var shouldRefreshAppNames = true

    // MARK: - Lifecycle

    init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true
        lastError = nil

        refresh()

        let newTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        newTimer.schedule(deadline: .now() + pollInterval, repeating: pollInterval)
        newTimer.setEventHandler { [weak self] in
            self?.refresh()
        }
        newTimer.resume()
        timer = newTimer
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    deinit {
        stop()
    }

    // MARK: - Process Management

    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            guard !self.isRefreshing else { return }
            self.isRefreshing = true
            defer {
                self.isRefreshing = false
            }

            // Refresh NSWorkspace app names every other cycle to reduce MainActor blocking
            self.shouldRefreshAppNames.toggle()
            if self.shouldRefreshAppNames || self.appNameCache.isEmpty {
                self.appNameCache = await MainActor.run {
                    var map: [pid_t: String] = [:]
                    for app in NSWorkspace.shared.runningApplications {
                        if let name = app.localizedName {
                            map[app.processIdentifier] = name
                        }
                    }
                    return map
                }
            }
            let appNameMap = self.appNameCache

            let pids = DarwinProcess.getAllPIDs()
            let coreCount = ProcessInfo.processInfo.activeProcessorCount
            let portMap = PortScanner.getListeningPorts()

            var newProcesses: [LucidProcess] = []
            var currentCPUTimes: [pid_t: UInt64] = [:]

            let elapsedSeconds = self.pollInterval
            let prevCPUTimes = self.previousCPUTimes
            let llm = self.llmService

            // Batch PIDs into chunks to reduce task overhead (~8 tasks instead of ~400)
            let chunkSize = 50
            let pidChunks = stride(from: 0, to: pids.count, by: chunkSize).map {
                Array(pids[$0..<min($0 + chunkSize, pids.count)])
            }

            await withTaskGroup(of: [(LucidProcess, UInt64?)].self) { group in
                for chunk in pidChunks {
                    group.addTask {
                        var results: [(LucidProcess, UInt64?)] = []
                        for pid in chunk {
                            guard let name = DarwinProcess.getProcessName(pid: pid) else { continue }

                            let exePath = DarwinProcess.getProcessPath(pid: pid) ?? ""

                            // Fast path: dictionary/heuristic only, no LLM inference
                            var (description, safety) = await ProcessDictionary.smartLookup(
                                name: name,
                                path: exePath,
                                nsAppName: appNameMap[pid]
                            )

                            // Check LLM cache for previously identified unknowns
                            if safety == .unknown,
                               let cached = await llm.cachedResult(name: name, path: exePath) {
                                description = cached.0
                                safety = cached.1
                            }

                            let info = DarwinProcess.getProcessInfo(pid: pid)

                            let cpuUsage: Double
                            if let info {
                                let previousNanos = prevCPUTimes[pid] ?? info.cpuNanos
                                cpuUsage = DarwinProcess.calculateCPUPercentage(
                                    currentNanos: info.cpuNanos,
                                    previousNanos: previousNanos,
                                    elapsedSeconds: elapsedSeconds,
                                    coreCount: coreCount
                                )
                            } else {
                                cpuUsage = 0
                            }

                            let process = LucidProcess(
                                pid: pid,
                                name: name,
                                description: description,
                                cpuUsage: cpuUsage,
                                memoryBytes: info?.memoryBytes ?? 0,
                                safety: safety,
                                exePath: exePath,
                                ports: portMap[pid] ?? []
                            )
                            results.append((process, info?.cpuNanos))
                        }
                        return results
                    }
                }

                for await chunk in group {
                    for (process, cpuNanos) in chunk {
                        newProcesses.append(process)
                        if let nanos = cpuNanos {
                            currentCPUTimes[process.pid] = nanos
                        }
                    }
                }
            }

            // Identify unknown processes via LLM in background (non-blocking)
            let unknowns = newProcesses.filter { $0.safety == .unknown }
            if !unknowns.isEmpty {
                let llm = self.llmService
                Task.detached(priority: .background) {
                    for process in unknowns {
                        if let (desc, safety) = await llm.identifyProcess(name: process.name, path: process.exePath) {
                            // Results will be picked up on the next refresh cycle via the LLM cache
                            _ = (desc, safety)
                        }
                    }
                }
            }

            let finalProcesses = newProcesses.sorted()
            let finalCPUTimes = currentCPUTimes
            let counts = FilterCounts(
                total: newProcesses.count,
                system: newProcesses.filter { $0.safety == .system }.count,
                user: newProcesses.filter { $0.safety == .user }.count,
                unknown: newProcesses.filter { $0.safety == .unknown }.count
            )
            let ports = Array(Set(newProcesses.flatMap(\.ports))).sorted()

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.previousCPUTimes = finalCPUTimes
                self.processes = finalProcesses
                self.filterCounts = counts
                self.activePorts = ports
                self.updateSystemStats()
            }
        }
    }

    func killProcess(_ process: LucidProcess) -> Result<Void, DarwinError> {
        // Verify the PID still refers to the same process before killing
        guard let currentName = DarwinProcess.getProcessName(pid: process.pid),
              currentName == process.name else {
            return .failure(.failedToKill(pid: process.pid, description: "Process no longer exists or has changed"))
        }
        return DarwinProcess.killProcess(pid: process.pid)
    }

    func killProcesses(_ processes: [LucidProcess]) -> Result<Void, KillErrors> {
        var errors: [String] = []
        for process in processes {
            if case .failure(let error) = killProcess(process) {
                errors.append("\(process.name): \(error.localizedDescription)")
            }
        }
        return errors.isEmpty ? .success(()) : .failure(KillErrors(errors: errors))
    }

    struct KillErrors: Error {
        let errors: [String]
        var localizedDescription: String {
            errors.joined(separator: "\n")
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func updateSystemStats() {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = calculateUsedMemory()
        let totalCPU = calculateAverageCPU()

        let memoryPercent = (Double(usedMemory) / Double(totalMemory)) * 100

        var cpuHistory = previousCPUHistory
        cpuHistory.append(totalCPU)
        if cpuHistory.count > 12 {
            cpuHistory.removeFirst()
        }
        previousCPUHistory = cpuHistory

        var memoryHistory = previousMemoryHistory
        memoryHistory.append(memoryPercent)
        if memoryHistory.count > 12 {
            memoryHistory.removeFirst()
        }
        previousMemoryHistory = memoryHistory

        stats = SystemStats(
            cpuUsage: totalCPU,
            memoryUsage: memoryPercent,
            memoryBytes: usedMemory,
            totalMemoryBytes: totalMemory,
            timestamp: Date()
        )
        stats.cpuHistory = cpuHistory
        stats.memoryHistory = memoryHistory
    }

    private func calculateUsedMemory() -> UInt64 {
        processes.reduce(0) { $0 + $1.memoryBytes }
    }

    private func calculateAverageCPU() -> Double {
        let totalCPU = processes.reduce(0.0) { $0 + $1.cpuUsage }
        let coreCount = Double(ProcessInfo.processInfo.activeProcessorCount)
        return min(totalCPU / coreCount, 100.0)
    }
}
