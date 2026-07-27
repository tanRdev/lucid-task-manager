import Foundation
import AppKit
import os

/// Immutable snapshot produced by background sampling.
struct ProcessSnapshot: Sendable {
    let processes: [LucidProcess]
    let cpuTimes: [ProcessIdentity: UInt64]
    let sampleInstant: ContinuousClock.Instant
    let portError: String?
}

/// Background sampler isolated from UI state.
actor ProcessSampler {
    private let portScanner = PortScanner()
    private var previousCPUTimes: [ProcessIdentity: UInt64] = [:]
    private var previousSampleInstant: ContinuousClock.Instant?

    func sample(appNameMap: [pid_t: String]) async -> ProcessSnapshot {
        let pids = DarwinProcess.getAllPIDs()
        let portMap = await portScanner.getListeningPorts()
        let portError = await portScanner.lastError
        let now = ContinuousClock.now
        let measuredElapsed: Double = {
            guard let previous = previousSampleInstant else { return 2.0 }
            let duration = previous.duration(to: now)
            let seconds = Double(duration.components.seconds)
                + Double(duration.components.attoseconds) / 1e18
            return max(seconds, 0.001)
        }()

        let prevCPUTimes = previousCPUTimes
        let chunkSize = 50
        let pidChunks = stride(from: 0, to: pids.count, by: chunkSize).map {
            Array(pids[$0..<min($0 + chunkSize, pids.count)])
        }

        var newProcesses: [LucidProcess] = []
        var currentCPUTimes: [ProcessIdentity: UInt64] = [:]

        await withTaskGroup(of: [(LucidProcess, ProcessIdentity, UInt64?)].self) { group in
            for chunk in pidChunks {
                group.addTask {
                    var results: [(LucidProcess, ProcessIdentity, UInt64?)] = []
                    for pid in chunk {
                        guard let name = DarwinProcess.getProcessName(pid: pid) else { continue }
                        let exePath = DarwinProcess.getProcessPath(pid: pid) ?? ""
                        let (description, origin) = ProcessDictionary.smartLookup(
                            name: name,
                            path: exePath,
                            nsAppName: appNameMap[pid]
                        )

                        let info = DarwinProcess.getProcessInfo(pid: pid)
                        let identity = ProcessIdentity(
                            pid: pid,
                            startTime: info?.startTime ?? 0
                        )

                        let cpuUsage: Double
                        if let info {
                            let previousNanos = prevCPUTimes[identity] ?? info.cpuNanos
                            cpuUsage = DarwinProcess.calculateCPUPercentage(
                                currentNanos: info.cpuNanos,
                                previousNanos: previousNanos,
                                elapsedSeconds: measuredElapsed
                            )
                        } else {
                            cpuUsage = 0
                        }

                        let process = LucidProcess(
                            identity: identity,
                            name: name,
                            description: description,
                            cpuUsage: cpuUsage,
                            memoryBytes: info?.memoryBytes ?? 0,
                            origin: origin,
                            exePath: exePath,
                            ports: portMap[pid] ?? [],
                            userID: info?.userID ?? 0
                        )
                        results.append((process, identity, info?.cpuNanos))
                    }
                    return results
                }
            }

            for await chunk in group {
                for (process, identity, cpuNanos) in chunk {
                    newProcesses.append(process)
                    if let nanos = cpuNanos {
                        currentCPUTimes[identity] = nanos
                    }
                }
            }
        }

        previousCPUTimes = currentCPUTimes
        previousSampleInstant = now

        return ProcessSnapshot(
            processes: newProcesses.sorted(),
            cpuTimes: currentCPUTimes,
            sampleInstant: now,
            portError: portError
        )
    }
}

@MainActor
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
    var isPausedForInactivity = false
    var lastError: String?
    var lastUpdated: Date?
    var isLoading = true
    var selectedFilter: FilterCategory = .all
    var filterCounts = FilterCounts()
    var activePorts: [UInt16] = []
    var assistiveTechnologyActive = false

    struct FilterCounts: Sendable {
        var total: Int = 0
        var system: Int = 0
        var user: Int = 0
        var unknown: Int = 0
    }

    // MARK: - Private State
    private var timer: DispatchSourceTimer?
    private var refreshTask: Task<Void, Never>?
    private var previousCPUHistory: [Double] = []
    private var previousMemoryHistory: [Double] = []
    private let foregroundPollInterval: TimeInterval = 2.0
    private let backgroundPollInterval: TimeInterval = 5.0
    private let logger = Logger(subsystem: "com.tan.lucid", category: "ProcessMonitor")
    private let timerQueue = DispatchQueue(label: "com.tan.lucid.timer", qos: .userInitiated)
    private let sampler = ProcessSampler()

    private var appNameCache: [pid_t: String] = [:]
    private var shouldRefreshAppNames = true
    private var isRefreshing = false

    // MARK: - Lifecycle

    init() {}

    func start(background: Bool = false) {
        isPausedForInactivity = false
        guard !isRunning else {
            rescheduleTimer(interval: background ? backgroundPollInterval : foregroundPollInterval)
            return
        }
        isRunning = true
        lastError = nil

        refresh()
        rescheduleTimer(interval: background ? backgroundPollInterval : foregroundPollInterval)
    }

    /// Continue sampling at a lower cadence while inactive.
    func enterBackgroundCadence() {
        guard isRunning else {
            start(background: true)
            return
        }
        isPausedForInactivity = false
        rescheduleTimer(interval: backgroundPollInterval)
    }

    func stop(reason: String? = nil) {
        isRunning = false
        isPausedForInactivity = reason != nil
        timer?.cancel()
        timer = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func rescheduleTimer(interval: TimeInterval) {
        timer?.cancel()
        let newTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        newTimer.schedule(deadline: .now() + interval, repeating: interval)
        newTimer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.refresh()
            }
        }
        newTimer.resume()
        timer = newTimer
    }

    // MARK: - Process Management

    func refresh() {
        // Coalesce while assistive tech is traversing, and skip overlapping work.
        if assistiveTechnologyActive || isRefreshing {
            return
        }

        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            self.isRefreshing = true
            defer { self.isRefreshing = false }

            self.shouldRefreshAppNames.toggle()
            if self.shouldRefreshAppNames || self.appNameCache.isEmpty {
                var map: [pid_t: String] = [:]
                for app in NSWorkspace.shared.runningApplications {
                    if let name = app.localizedName {
                        map[app.processIdentifier] = name
                    }
                }
                self.appNameCache = map
            }
            let appNameMap = self.appNameCache

            do {
                let snapshot = await self.sampler.sample(appNameMap: appNameMap)
                guard !Task.isCancelled else { return }

                let counts = FilterCounts(
                    total: snapshot.processes.count,
                    system: snapshot.processes.filter { $0.origin == .system }.count,
                    user: snapshot.processes.filter { $0.origin == .user }.count,
                    unknown: snapshot.processes.filter { $0.origin == .unknown }.count
                )
                let ports = Array(Set(snapshot.processes.flatMap(\.ports))).sorted()

                // Preserve a port filter that disappeared with a clear explanation.
                if case .port(let port) = self.selectedFilter, !ports.contains(port) {
                    self.lastError = "Port \(port) is no longer listening. Showing all processes."
                    self.selectedFilter = .all
                } else if let portError = snapshot.portError {
                    self.lastError = portError
                }

                self.processes = snapshot.processes
                self.filterCounts = counts
                self.activePorts = ports
                self.lastUpdated = Date()
                self.isLoading = false
                self.updateSystemStats()
            }
        }
    }

    func setAssistiveTechnologyActive(_ active: Bool) {
        assistiveTechnologyActive = active
        if !active && isRunning {
            refresh()
        }
    }

    @discardableResult
    func killProcess(_ process: LucidProcess) -> Result<Void, DarwinError> {
        guard process.origin.allowsTermination else {
            return .failure(.protected(pid: process.pid, name: process.name))
        }
        guard DarwinProcess.matchesIdentity(process.identity, expectedName: process.name) else {
            return .failure(.identityMismatch(pid: process.pid))
        }
        return DarwinProcess.killProcess(pid: process.pid)
    }

    func killProcesses(_ processes: [LucidProcess]) -> Result<Void, KillErrors> {
        var errors: [String] = []
        for process in processes {
            if process.origin.isProtected {
                errors.append("\(process.name): protected system process")
                continue
            }
            if case .failure(let error) = killProcess(process) {
                errors.append("\(process.name): \(error.localizedDescription)")
            }
        }
        return errors.isEmpty ? .success(()) : .failure(KillErrors(errors: errors))
    }

    func killableProcesses(onPort port: UInt16) -> [LucidProcess] {
        processes.filter { $0.ports.contains(port) && $0.origin.allowsTermination }
    }

    func protectedProcesses(onPort port: UInt16) -> [LucidProcess] {
        processes.filter { $0.ports.contains(port) && $0.origin.isProtected }
    }

    struct KillErrors: Error, LocalizedError {
        let errors: [String]
        var errorDescription: String? {
            errors.joined(separator: "\n")
        }
        var localizedDescription: String {
            errors.joined(separator: "\n")
        }
    }

    // MARK: - Private Helpers

    private func updateSystemStats() {
        let memory = DarwinProcess.hostMemoryUsedBytes()
        let totalMemory = memory?.total ?? ProcessInfo.processInfo.physicalMemory
        let usedMemory = memory?.used ?? 0
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let totalCPU = DarwinProcess.calculateSystemCPUPercentage(
            processCPUPercentages: processes.map(\.cpuUsage),
            coreCount: coreCount
        )

        let memoryPercent = totalMemory > 0
            ? (Double(usedMemory) / Double(totalMemory)) * 100
            : 0

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
}
