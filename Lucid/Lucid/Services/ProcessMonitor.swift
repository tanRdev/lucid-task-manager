import Foundation
import AppKit
import os

@Observable
@MainActor
final class ProcessMonitor {
    // MARK: - Composed Stores (New Architecture)
    let processStore = ProcessStore()
    let statsStore = SystemStatsStore()
    let filterState = FilterState()

    // MARK: - Proxy Properties (for backward compatibility during migration)
    var processes: [LucidProcess] { processStore.processes }
    var stats: SystemStats { statsStore.stats }
    var selectedFilter: FilterCategory {
        get { filterState.selectedFilter }
        set { filterState.applyFilter(newValue) }
    }
    var filterCounts: ProcessStore.FilterCounts { processStore.filterCounts }
    var activePorts: [UInt16] { processStore.activePorts }

    // MARK: - Observable State (remaining in monitor)
    var isRunning = false
    var lastError: String?

    // MARK: - Private State
    private var timer: DispatchSourceTimer?
    private var previousCPUTimes: [pid_t: UInt64] = [:]
    private let pollInterval: TimeInterval = 2.0
    private let logger = Logger(subsystem: "com.tan.lucid", category: "ProcessMonitor")
    private let timerQueue = DispatchQueue(label: "com.tan.lucid.timer", qos: .userInitiated)

    private let refreshLock = NSLock()
    private var _isRefreshing = false
    private var isRefreshing: Bool {
        get { refreshLock.withLock { _isRefreshing } }
        set { refreshLock.withLock { _isRefreshing = newValue } }
    }

    private let llmService = LLMService()
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
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        newTimer.resume()
        timer = newTimer
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    // MARK: - Refresh (Orchestrates Store Updates)

    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            guard !self.isRefreshing else { return }
            self.isRefreshing = true
            defer { self.isRefreshing = false }

            // Refresh app name cache every other cycle
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

            // Batch PIDs into chunks
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

                            var (description, safety) = await ProcessDictionary.smartLookup(
                                name: name,
                                path: exePath,
                                nsAppName: appNameMap[pid]
                            )

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

            // LLM identification for unknowns (background)
            let unknowns = newProcesses.filter { $0.safety == .unknown }
            if !unknowns.isEmpty {
                Task.detached(priority: .background) {
                    for process in unknowns {
                        _ = await llm.identifyProcess(name: process.name, path: process.exePath)
                    }
                }
            }

            let finalCPUTimes = currentCPUTimes

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.previousCPUTimes = finalCPUTimes
                self.processStore.updateProcesses(newProcesses)
                self.updateSystemStats()
            }
        }
    }

    // MARK: - Process Management

    func killProcess(_ process: LucidProcess) -> Result<Void, DarwinError> {
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

    func processes(for port: UInt16) -> [pid_t] {
        processStore.processes(for: port)
    }

    struct KillErrors: Error {
        let errors: [String]
        var localizedDescription: String {
            errors.joined(separator: "\n")
        }
    }

    // MARK: - Private Helpers

    private func updateSystemStats() {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = processes.reduce(0) { $0 + $1.memoryBytes }
        let totalCPU = processes.reduce(0.0) { $0 + $1.cpuUsage }
        let coreCount = Double(ProcessInfo.processInfo.activeProcessorCount)
        let averageCPU = min(totalCPU / coreCount, 100.0)
        let memoryPercent = (Double(usedMemory) / Double(totalMemory)) * 100

        let stats = SystemStats(
            cpuUsage: averageCPU,
            memoryUsage: memoryPercent,
            memoryBytes: usedMemory,
            totalMemoryBytes: totalMemory,
            timestamp: Date()
        )

        statsStore.updateStats(stats)
    }
}