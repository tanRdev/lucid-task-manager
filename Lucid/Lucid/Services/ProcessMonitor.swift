import Foundation
import AppKit
import SwiftUI
import os

/// Immutable snapshot produced by background sampling.
struct ProcessSnapshot: Sendable {
    let processes: [LucidProcess]
    let filterCounts: ProcessMonitor.FilterCounts
    let activePorts: [UInt16]
    let portError: String?
    /// Host-wide CPU busy % from `host_processor_info`; nil until the second sample.
    let hostCPUUsage: Double?
}

/// Background sampler isolated from UI state.
actor ProcessSampler {
    private let portScanner = PortScanner()
    private var previousCPUTimes: [ProcessIdentity: UInt64] = [:]
    private var previousSampleInstant: ContinuousClock.Instant?
    private var cachedPortMap: [pid_t: [UInt16]] = [:]
    private var portSampleCounter = 0
    private var previousHostCPU: DarwinProcess.HostCPUSample?

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

        // Host-wide CPU from the kernel — catches work by processes we cannot
        // sample (root daemons fail proc_pidinfo and would otherwise read as 0).
        let hostSample = DarwinProcess.hostCPULoad()
        let hostCPUUsage: Double?
        if let current = hostSample, let previous = previousHostCPU {
            hostCPUUsage = DarwinProcess.hostCPUPercentage(current: current, previous: previous)
        } else {
            hostCPUUsage = nil
        }
        if let hostSample { previousHostCPU = hostSample }

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
            portError: portError,
            hostCPUUsage: hostCPUUsage
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

    struct FilterCounts: Sendable {
        var total: Int = 0
        var system: Int = 0
        var user: Int = 0
        var unknown: Int = 0
    }

    // MARK: - Private State
    @ObservationIgnored private var timer: DispatchSourceTimer?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
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
        if isRefreshing {
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
                self.updateSystemStats(using: snapshot)
            }
        }
    }

    // MARK: - Termination

    /// Why a process needs an explicit extra confirmation before killing,
    /// or nil when the standard single confirmation is sufficient.
    static func riskFactor(for process: LucidProcess, currentUserID: uid_t = geteuid()) -> String? {
        if process.origin.requiresConfirmation {
            return "origin is unknown"
        }
        if process.userID != currentUserID {
            return "owned by uid \(process.userID), not the current user (\(currentUserID))"
        }
        return nil
    }

    /// Pure decision split applied before any signal is sent — unit-testable.
    static func classifyKillTargets(
        _ processes: [LucidProcess],
        confirmedRisky: Bool,
        currentUserID: uid_t = geteuid()
    ) -> (allowed: [LucidProcess], errors: [String], risky: [LucidProcess]) {
        var allowed: [LucidProcess] = []
        var errors: [String] = []
        var risky: [LucidProcess] = []

        for process in processes {
            if process.origin.isProtected {
                errors.append("\(process.name): protected system process")
                continue
            }
            if !confirmedRisky,
               let risk = riskFactor(for: process, currentUserID: currentUserID) {
                risky.append(process)
                errors.append("\(process.name): \(risk) — confirmation required")
                continue
            }
            allowed.append(process)
        }
        return (allowed, errors, risky)
    }

    /// Identity re-check (PID-reuse guard) then SIGTERM, or SIGKILL when `force`.
    @discardableResult
    private func signalKill(_ process: LucidProcess, force: Bool) -> Result<Void, DarwinError> {
        guard DarwinProcess.matchesIdentity(process.identity, expectedName: process.name) else {
            return .failure(.identityMismatch(pid: process.pid))
        }
        return DarwinProcess.killProcess(pid: process.pid, force: force)
    }

    /// Signals every target, then verifies each one actually exited.
    /// All failures aggregate into a single `KillErrors`:
    /// `riskyTargets` need confirmation, `survivors` outlived the signal.
    @discardableResult
    func killProcesses(
        _ processes: [LucidProcess],
        confirmedRisky: Bool = false,
        force: Bool = false
    ) async -> Result<Void, KillErrors> {
        let classification = Self.classifyKillTargets(
            processes,
            confirmedRisky: confirmedRisky
        )
        var errors = classification.errors
        var signaled: [LucidProcess] = []

        for process in classification.allowed {
            switch signalKill(process, force: force) {
            case .success:
                signaled.append(process)
            case .failure(let error):
                errors.append("\(process.name): \(error.localizedDescription)")
            }
        }

        var survivors: [LucidProcess] = []
        if !signaled.isEmpty {
            survivors = await waitForExit(signaled, timeout: .milliseconds(1200))
            for process in survivors {
                let signal = force ? "SIGKILL" : "SIGTERM"
                errors.append("\(process.name): still running after \(signal)")
            }
        }

        guard errors.isEmpty else {
            return .failure(
                KillErrors(
                    errors: errors,
                    riskyTargets: classification.risky,
                    survivors: survivors
                )
            )
        }
        return .success(())
    }

    /// Polls until every signaled process exits or `timeout` elapses; returns survivors.
    private func waitForExit(_ processes: [LucidProcess], timeout: Duration) async -> [LucidProcess] {
        let deadline = ContinuousClock.now + timeout
        var remaining = processes
        while !remaining.isEmpty, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(100))
            remaining = remaining.filter { DarwinProcess.isAlive(pid: $0.pid) }
        }
        return remaining
    }

    func killableProcesses(onPort port: UInt16) -> [LucidProcess] {
        processes.filter { $0.ports.contains(port) && $0.origin.allowsTermination }
    }

    func protectedProcesses(onPort port: UInt16) -> [LucidProcess] {
        processes.filter { $0.ports.contains(port) && $0.origin.isProtected }
    }

    struct KillErrors: Error, LocalizedError {
        let errors: [String]
        /// Targets refused because they need an explicit extra confirmation
        /// (unknown origin or owned by another user).
        var riskyTargets: [LucidProcess] = []
        /// Targets that were signaled but still alive after the grace period —
        /// candidates for an explicit SIGKILL escalation.
        var survivors: [LucidProcess] = []

        var errorDescription: String? {
            errors.joined(separator: "\n")
        }
        var localizedDescription: String {
            errors.joined(separator: "\n")
        }
    }

    private func updateSystemStats(using snapshot: ProcessSnapshot) {
        let memory = DarwinProcess.hostMemoryUsedBytes()
        let totalMemory = memory?.total ?? ProcessInfo.processInfo.physicalMemory
        let usedMemory = memory?.used ?? 0

        // Prefer the kernel's host-wide figure; fall back to the per-process
        // sum for the first sample (no delta yet) or if host_processor_info fails.
        let totalCPU = snapshot.hostCPUUsage ?? DarwinProcess.calculateSystemCPUPercentage(
            processCPUPercentages: snapshot.processes.map(\.cpuUsage),
            coreCount: ProcessInfo.processInfo.activeProcessorCount
        )

        let memoryPercent = totalMemory > 0
            ? (Double(usedMemory) / Double(totalMemory)) * 100
            : 0

        stats = SystemStats(
            cpuUsage: totalCPU,
            memoryUsage: memoryPercent,
            memoryBytes: usedMemory,
            totalMemoryBytes: totalMemory,
            timestamp: Date()
        )
    }
}
