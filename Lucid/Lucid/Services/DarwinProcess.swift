import Foundation
import Darwin

enum DarwinError: Error, LocalizedError, Sendable {
    case failedToKill(pid: pid_t, description: String)
    case protected(pid: pid_t, name: String)
    case identityMismatch(pid: pid_t)

    var errorDescription: String? {
        switch self {
        case .failedToKill(let pid, let description):
            return "Failed to kill process \(pid): \(description)"
        case .protected(let pid, let name):
            return "Refused to terminate protected system process \(name) (PID \(pid))"
        case .identityMismatch(let pid):
            return "Process \(pid) no longer matches the selected identity"
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

        var pids = [pid_t](repeating: 0, count: Int(pidCount))
        pidCount = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))

        return Array(pids.prefix(Int(pidCount)))
    }

    static func getProcessName(pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(4096))
        let ret = proc_pidpath(pid, &buffer, UInt32(buffer.count))

        if ret > 0, let name = String(validatingUTF8: buffer) {
            return URL(fileURLWithPath: name).lastPathComponent
        }

        var nameBuffer = [CChar](repeating: 0, count: 16)
        if proc_name(pid, &nameBuffer, UInt32(nameBuffer.count)) > 0 {
            return String(validatingUTF8: nameBuffer)
        }

        return nil
    }

    static func getProcessPath(pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(4096))
        let ret = proc_pidpath(pid, &buffer, UInt32(buffer.count))

        if ret > 0 {
            return String(validatingUTF8: buffer)
        }
        return nil
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

    /// Confirms the live process still matches the selected identity (PID + start time + name).
    static func matchesIdentity(_ identity: ProcessIdentity, expectedName: String) -> Bool {
        guard let name = getProcessName(pid: identity.pid), name == expectedName else {
            return false
        }
        guard let info = getProcessInfo(pid: identity.pid) else {
            return false
        }
        // startTime 0 means we couldn't read BSD info at sample time — fall back to name+pid.
        if identity.startTime == 0 || info.startTime == 0 {
            return true
        }
        return info.startTime == identity.startTime
    }

    // MARK: - Process Control

    static func killProcess(pid: pid_t) -> Result<Void, DarwinError> {
        if kill(pid, SIGTERM) == 0 {
            return .success(())
        } else {
            let error = String(cString: strerror(errno))
            return .failure(.failedToKill(pid: pid, description: error))
        }
    }

    // MARK: - Host memory

    /// Activity Monitor–style memory used: active + wired + compressed pages.
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

    // MARK: - CPU helpers

    /// Activity Monitor–compatible per-process CPU: one fully busy core == 100%.
    /// Values may exceed 100% on multi-core machines. Does not divide by core count.
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

    /// Whole-machine CPU: sum of per-process core usage divided once by logical core count.
    static func calculateSystemCPUPercentage(
        processCPUPercentages: [Double],
        coreCount: Int
    ) -> Double {
        guard coreCount > 0 else { return 0 }
        let total = processCPUPercentages.reduce(0.0, +)
        return min(total / Double(coreCount), 100.0)
    }
}
