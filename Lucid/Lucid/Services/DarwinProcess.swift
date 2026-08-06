import Foundation
import Darwin

enum DarwinError: Error, LocalizedError, Sendable {
    case failedToKill(pid: pid_t, description: String)
    case protected(pid: pid_t, name: String)
    case identityMismatch(pid: pid_t)
    case requiresConfirmation(pid: pid_t, name: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .failedToKill(let pid, let description):
            return "Failed to kill process \(pid): \(description)"
        case .protected(let pid, let name):
            return "Refused to terminate protected system process \(name) (PID \(pid))"
        case .identityMismatch(let pid):
            return "Process \(pid) no longer matches the selected identity"
        case .requiresConfirmation(let pid, let name, let reason):
            return "\(name) (PID \(pid)) requires explicit confirmation: \(reason)"
        }
    }
}

struct ProcessSampleInfo: Sendable {
    let cpuNanos: UInt64
    let memoryBytes: UInt64
    let startTime: UInt64
    let userID: uid_t
}

enum DarwinProcess {
    // MARK: - Process Enumeration

    static func getAllPIDs() -> [pid_t] {
        var pidCount = proc_listallpids(nil, 0)
        guard pidCount > 0 else { return [] }

        // Over-allocate: new processes can spawn between the sizing call and the fill call.
        let capacity = Int(pidCount) + 32
        var pids = [pid_t](repeating: 0, count: capacity)
        pidCount = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard pidCount > 0 else { return [] }

        return Array(pids.prefix(min(Int(pidCount), capacity)))
    }

    /// Single `proc_pidpath` call — name is the last path component.
    static func getProcessNameAndPath(pid: pid_t) -> (name: String, path: String)? {
        var buffer = [CChar](repeating: 0, count: Int(4096))
        let ret = proc_pidpath(pid, &buffer, UInt32(buffer.count))

        if ret > 0, let path = String(validatingUTF8: buffer), !path.isEmpty {
            return (URL(fileURLWithPath: path).lastPathComponent, path)
        }

        var nameBuffer = [CChar](repeating: 0, count: 16)
        if proc_name(pid, &nameBuffer, UInt32(nameBuffer.count)) > 0,
           let name = String(validatingUTF8: nameBuffer), !name.isEmpty {
            return (name, "")
        }

        return nil
    }

    static func getProcessName(pid: pid_t) -> String? {
        getProcessNameAndPath(pid: pid)?.name
    }

    static func getProcessPath(pid: pid_t) -> String? {
        let path = getProcessNameAndPath(pid: pid)?.path
        return (path?.isEmpty == false) ? path : nil
    }

    static func getProcessInfo(pid: pid_t) -> ProcessSampleInfo? {
        var taskInfo = proc_taskinfo()
        let taskInfoSize = MemoryLayout<proc_taskinfo>.stride
        let taskRet = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(taskInfoSize))
        guard taskRet > 0 else { return nil }

        var bsdInfo = proc_bsdinfo()
        let bsdSize = MemoryLayout<proc_bsdinfo>.stride
        let bsdRet = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, Int32(bsdSize))

        let startTime = bsdRet > 0 ? bsdInfo.pbi_start_tvsec : 0
        let userID = bsdRet > 0 ? bsdInfo.pbi_uid : 0

        return ProcessSampleInfo(
            cpuNanos: taskInfo.pti_total_user + taskInfo.pti_total_system,
            memoryBytes: UInt64(taskInfo.pti_resident_size),
            startTime: startTime,
            userID: userID
        )
    }

    /// Fail-closed identity comparison: a start time of 0 means the kernel
    /// refused `PROC_PIDTBSDINFO` (common for root-owned processes), so the
    /// identity cannot be confirmed and the kill must be refused.
    static func identityStartTimesMatch(expected: UInt64, observed: UInt64) -> Bool {
        guard expected != 0, observed != 0 else { return false }
        return expected == observed
    }

    static func matchesIdentity(_ identity: ProcessIdentity, expectedName: String) -> Bool {
        guard let name = getProcessName(pid: identity.pid), name == expectedName else {
            return false
        }
        guard let info = getProcessInfo(pid: identity.pid) else {
            return false
        }
        return identityStartTimesMatch(expected: identity.startTime, observed: info.startTime)
    }

    /// True while `pid` refers to a live process. `EPERM` still means alive.
    static func isAlive(pid: pid_t) -> Bool {
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }

    static func killProcess(pid: pid_t, force: Bool = false) -> Result<Void, DarwinError> {
        let signal = force ? SIGKILL : SIGTERM
        if kill(pid, signal) == 0 {
            return .success(())
        } else {
            let error = String(cString: strerror(errno))
            return .failure(.failedToKill(pid: pid, description: error))
        }
    }

    // MARK: - Host CPU

    /// Cumulative host CPU tick counters across all cores.
    struct HostCPUSample: Sendable, Equatable {
        let user: UInt64
        let system: UInt64
        let idle: UInt64
        let nice: UInt64

        var total: UInt64 { user + system + idle + nice }
        var busy: UInt64 { user + system + nice }
    }

    /// Real host-wide CPU load via `host_processor_info` — includes work done
    /// by processes we cannot sample (e.g. root daemons), unlike per-process sums.
    static func hostCPULoad() -> HostCPUSample? {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &cpuInfoCount
        )
        guard result == KERN_SUCCESS, let cpuInfo else { return nil }
        defer {
            let size = vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_host_self(), vm_address_t(bitPattern: cpuInfo), size)
        }

        var user: UInt64 = 0
        var system: UInt64 = 0
        var idle: UInt64 = 0
        var nice: UInt64 = 0
        let stride = Int(CPU_STATE_MAX)
        for core in 0..<Int(processorCount) {
            let base = core * stride
            user += UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_USER)]))
            system += UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_SYSTEM)]))
            idle += UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_IDLE)]))
            nice += UInt64(UInt32(bitPattern: cpuInfo[base + Int(CPU_STATE_NICE)]))
        }
        return HostCPUSample(user: user, system: system, idle: idle, nice: nice)
    }

    /// Busy percentage between two cumulative host samples.
    static func hostCPUPercentage(current: HostCPUSample, previous: HostCPUSample) -> Double {
        guard current.total > previous.total, current.busy >= previous.busy else { return 0 }
        let busyDelta = Double(current.busy - previous.busy)
        let totalDelta = Double(current.total - previous.total)
        return min((busyDelta / totalDelta) * 100.0, 100.0)
    }

    static func hostMemoryUsedBytes() -> (used: UInt64, total: UInt64)? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let usedPages = UInt64(stats.active_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.compressor_page_count)
        let used = usedPages * pageSize
        let total = ProcessInfo.processInfo.physicalMemory
        return (used, total)
    }

    static func calculateCPUPercentage(
        currentNanos: UInt64,
        previousNanos: UInt64,
        elapsedSeconds: Double
    ) -> Double {
        guard elapsedSeconds > 0, currentNanos >= previousNanos else { return 0 }

        let deltaNanos = Double(currentNanos - previousNanos)
        let allowedNanos = elapsedSeconds * 1e9
        return (deltaNanos / allowedNanos) * 100.0
    }

    static func calculateSystemCPUPercentage(
        processCPUPercentages: [Double],
        coreCount: Int
    ) -> Double {
        guard coreCount > 0 else { return 0 }
        let total = processCPUPercentages.reduce(0.0, +)
        return min(total / Double(coreCount), 100.0)
    }
}
