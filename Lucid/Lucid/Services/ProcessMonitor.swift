import Foundation
import AppKit
import SwiftUI
import os

/// Immutable snapshot produced by background sampling.
struct ProcessSnapshot: Sendable {
    let processes: [LucidProcess]
    let filterCounts: ProcessMonitor.FilterCounts
    let activePorts: [UInt16]
    let sampleInstant: ContinuousClock.Instant
    let portError: String?
}

/// Background sampler isolated from UI state.
actor ProcessSampler {
    private let portScanner = PortScanner()
    private var previousCPUTimes: [ProcessIdentity: UInt64] = [:]
    private var previousSampleInstant: ContinuousClock.Instant?
    private var cachedPortMap: [pid_t: [UInt16]] = [:]
    private var portSampleCounter = 0

    func sample(appNameMap: [pid_t: String]) async -> ProcessSnapshot {
        let pids = DarwinProcess.getAllPIDs()
        let now = ContinuousClock.now
        let measuredElapsed: Double = {
            guard let previous = previousSampleInstant else { return 2.0 }
            let duration = previous.duration(to: now)
            let seconds = Double(duration.components.seconds)
                + Double(duration.components.attoseconds) / 1e18
            return max(seconds, 0.001)
        }()

        // Ports change slowly — refresh every 3rd sample (~6–9s) instead of every tick.
        portSampleCounter += 1
        var portError: String?
        if portSampleCounter == 1 || portSampleCounter % 3 == 0 || cachedPortMap.isEmpty {
            cachedPortMap = await portScanner.getListeningPorts()
            portError = await portScanner.lastError
        }
        let portMap = cachedPortMap
        let prevCPUTimes = previousCPUTimes

        // Serial scan is faster than TaskGroup for syscall-bound work (less scheduling overhead).
        var newProcesses: [LucidProcess] = []
        newProcesses.reserveCapacity(pids.count)
        var currentCPUTimes: [ProcessIdentity: UInt64] = [:]
        currentCPUTimes.reserveCapacity(pids.count)

        var systemCount = 0
        var userCount = 0
        var unknownCount = 0
        var portSet = Set<UInt16>()

        for pid in pids {
            guard let (name, exePath) = DarwinProcess.getProcessNameAndPath(pid: pid) else { continue }

            let (description, origin) = ProcessDictionary.smartLookup(
                name: name,
                path: exePath,
                nsAppName: appNameMap[pid]
            )

            let info = DarwinProcess.getProcessInfo(pid: pid)
            let identity = ProcessIdentity(pid: pid, startTime: info?.startTime ?? 0)

            let cpuUsage: Double
            if let info {
                let previousNanos = prevCPUTimes[identity] ?? info.cpuNanos
                cpuUsage = DarwinProcess.calculateCPUPercentage(
                    currentNanos: info.cpuNanos,
                    previousNanos: previousNanos,
                    elapsedSeconds: measuredElapsed
                )
                currentCPUTimes[identity] = info.cpuNanos
            } else {
                cpuUsage = 0
            }

            let ports = portMap[pid] ?? []
            for port in ports { portSet.insert(port) }

            switch origin {
            case .system: systemCount += 1
            case .user: userCount += 1
            case .unknown: unknownCount += 1
            }

            newProcesses.append(
                LucidProcess(
                    identity: identity,
                    name: name,
                    description: description,
                    cpuUsage: cpuUsage,
                    memoryBytes: info?.memoryBytes ?? 0,
                    origin: origin,
                    exePath: exePath,
                    ports: ports,
                    userID: info?.userID ?? 0
                )
            )
        }

        previousCPUTimes = currentCPUTimes
        previousSampleInstant = now

        let counts = ProcessMonitor.FilterCounts(
            total: newProcesses.count,
            system: systemCount,
            user: userCount,
            unknown: unknownCount
        )

        return ProcessSnapshot(
            processes: newProcesses,
            filterCounts: counts,
            activePorts: portSet.sorted(),
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
    @ObservationIgnored private var timer: DispatchSourceTimer?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var previousCPUHistory: [Double] = []
    @ObservationIgnored private var previousMemoryHistory: [Double] = []
    @ObservationIgnored private let foregroundPollInterval: TimeInterval = 2.5
    @ObservationIgnored private let backgroundPollInterval: TimeInterval = 6.0
    @ObservationIgnored private let logger = Logger(subsystem: "com.tan.lucid", category: "ProcessMonitor")
    @ObservationIgnored private let timerQueue = DispatchQueue(label: "com.tan.lucid.timer", qos: .utility)
    @ObservationIgnored private let sampler = ProcessSampler()
    @ObservationIgnored private var appNameCache: [pid_t: String] = [:]
    @ObservationIgnored private var appNameRefreshCounter = 0
    @ObservationIgnored private var isRefreshing = false

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
        newTimer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(200))
        newTimer.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.refresh()
            }
        }
        newTimer.resume()
        timer = newTimer
    }

    func refresh() {
        if assistiveTechnologyActive || isRefreshing {
            return
        }

        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            self.isRefreshing = true
            defer { self.isRefreshing = false }

            // App names rarely change — refresh every other sample.
            self.appNameRefreshCounter += 1
            if self.appNameRefreshCounter == 1 || self.appNameRefreshCounter % 2 == 0 || self.appNameCache.isEmpty {
                var map: [pid_t: String] = [:]
                map.reserveCapacity(64)
                for app in NSWorkspace.shared.runningApplications {
                    if let name = app.localizedName {
                        map[app.processIdentifier] = name
                    }
                }
                self.appNameCache = map
            }
            let appNameMap = self.appNameCache

            let snapshot = await self.sampler.sample(appNameMap: appNameMap)
            guard !Task.isCancelled else { return }

            if case .port(let port) = self.selectedFilter, !snapshot.activePorts.contains(port) {
                self.lastError = "Port \(LucidFormat.port(port)) is no longer listening. Showing all processes."
                self.selectedFilter = .all
            } else if let portError = snapshot.portError {
                self.lastError = portError
            }

            // Disable implicit animations so Table swaps don't hitch the window.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.processes = snapshot.processes
                self.filterCounts = snapshot.filterCounts
                self.activePorts = snapshot.activePorts
                self.lastUpdated = Date()
                self.isLoading = false
                self.updateSystemStats(using: snapshot.processes)
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

    private func updateSystemStats(using processes: [LucidProcess]) {
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
        if cpuHistory.count > 12 { cpuHistory.removeFirst() }
        previousCPUHistory = cpuHistory

        var memoryHistory = previousMemoryHistory
        memoryHistory.append(memoryPercent)
        if memoryHistory.count > 12 { memoryHistory.removeFirst() }
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
