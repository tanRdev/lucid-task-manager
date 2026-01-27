import Foundation
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

    // MARK: - Private State
    private var timer: DispatchSourceTimer?
    private var previousCPUTimes: [pid_t: UInt64] = [:]
    private var previousCPUHistory: [Double] = []
    private var previousMemoryHistory: [Double] = []
    private let pollInterval: TimeInterval = 3.0
    private let logger = Logger(subsystem: "com.tan.lucid", category: "ProcessMonitor")
    private let timerQueue = DispatchQueue(label: "com.tan.lucid.timer", qos: .userInitiated)
    private var isRefreshing = false

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
        guard !isRefreshing else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.isRefreshing = true

            let pids = DarwinProcess.getAllPIDs()
            let coreCount = ProcessInfo.processInfo.activeProcessorCount

            var newProcesses: [LucidProcess] = []
            var currentCPUTimes: [pid_t: UInt64] = [:]

            let elapsedSeconds = self.pollInterval

            for pid in pids {
                guard let name = DarwinProcess.getProcessName(pid: pid) else { continue }

                let (description, safety) = ProcessDictionary.lookup(name) ?? (name, .unknown)

                guard let info = DarwinProcess.getProcessInfo(pid: pid) else {
                    // Root/privileged process - show zero metrics
                    let process = LucidProcess(
                        pid: pid,
                        name: name,
                        description: description,
                        cpuUsage: 0,
                        memoryBytes: 0,
                        safety: safety,
                        exePath: DarwinProcess.getProcessPath(pid: pid) ?? ""
                    )
                    newProcesses.append(process)
                    continue
                }

                currentCPUTimes[pid] = info.cpuNanos

                let previousNanos = self.previousCPUTimes[pid] ?? info.cpuNanos
                let cpuUsage = DarwinProcess.calculateCPUPercentage(
                    currentNanos: info.cpuNanos,
                    previousNanos: previousNanos,
                    elapsedSeconds: elapsedSeconds,
                    coreCount: coreCount
                )

                let process = LucidProcess(
                    pid: pid,
                    name: name,
                    description: description,
                    cpuUsage: cpuUsage,
                    memoryBytes: info.memoryBytes,
                    safety: safety,
                    exePath: DarwinProcess.getProcessPath(pid: pid) ?? ""
                )
                newProcesses.append(process)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.previousCPUTimes = currentCPUTimes
                self.processes = newProcesses.sorted()
                self.updateSystemStats()
                self.isRefreshing = false
            }
        }
    }

    func killProcess(_ process: LucidProcess) -> Result<Void, DarwinError> {
        DarwinProcess.killProcess(pid: process.pid)
    }

    // MARK: - Private Helpers

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
