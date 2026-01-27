import Foundation
import AppKit

enum DarwinError: Error, LocalizedError {
    case failedToKill(pid: pid_t, description: String)

    var errorDescription: String? {
        switch self {
        case .failedToKill(let pid, let description):
            return "Failed to kill process \(pid): \(description)"
        }
    }
}

struct DarwinProcess {
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

        // Fallback: try using proc_name (max 16 chars)
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

    static func getProcessInfo(pid: pid_t) -> (cpuNanos: UInt64, memoryBytes: UInt64)? {
        var taskInfo = proc_taskinfo()
        let taskInfoSize = MemoryLayout<proc_taskinfo>.stride

        let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(taskInfoSize))

        guard ret > 0 else { return nil }

        let cpuNanos = taskInfo.pti_total_user + taskInfo.pti_total_system
        let memoryBytes = UInt64(taskInfo.pti_resident_size)

        return (cpuNanos: cpuNanos, memoryBytes: memoryBytes)
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

    // MARK: - Helpers

    static func getRunningApplicationName(pid: pid_t) -> String? {
        for app in NSWorkspace.shared.runningApplications {
            if app.processIdentifier == pid {
                return app.localizedName
            }
        }
        return nil
    }

    static func calculateCPUPercentage(
        currentNanos: UInt64,
        previousNanos: UInt64,
        elapsedSeconds: Double,
        coreCount: Int
    ) -> Double {
        guard elapsedSeconds > 0 else { return 0 }

        let deltaNanos = Double(currentNanos - previousNanos)
        let allowedNanos = elapsedSeconds * Double(coreCount) * 1e9

        let percentage = (deltaNanos / allowedNanos) * 100.0
        return min(percentage, 100.0) // Cap at 100% per core group
    }
}
