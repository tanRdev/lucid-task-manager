import Foundation

struct ProcessIdentity: Hashable, Codable, Sendable {
    let pid: pid_t
    /// Kernel-reported process start time (seconds since epoch).
    let startTime: UInt64

    init(pid: pid_t, startTime: UInt64) {
        self.pid = pid
        self.startTime = startTime
    }
}

struct LucidProcess: Identifiable, Hashable, Comparable, Sendable {
    var id: ProcessIdentity { identity }

    let identity: ProcessIdentity
    let name: String
    let description: String
    let cpuUsage: Double
    let memoryBytes: UInt64
    let origin: ProcessOrigin
    let exePath: String
    let ports: [UInt16]
    let userID: uid_t

    var pid: pid_t { identity.pid }
    var startTime: UInt64 { identity.startTime }

    /// Prefer `origin`. Kept for call sites that still use the old name.
    var safety: ProcessOrigin { origin }

    var isProtected: Bool { origin.isProtected }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identity)
    }

    static func == (lhs: LucidProcess, rhs: LucidProcess) -> Bool {
        lhs.identity == rhs.identity
    }

    static func < (lhs: LucidProcess, rhs: LucidProcess) -> Bool {
        lhs.name < rhs.name
    }

    var memoryMB: Double {
        Double(memoryBytes) / (1024 * 1024)
    }

    var memoryFormatted: String {
        if memoryMB < 1024 {
            return String(format: "%.1f MB", memoryMB)
        } else {
            let gb = memoryMB / 1024
            return String(format: "%.1f GB", gb)
        }
    }

    var cpuFormatted: String {
        String(format: "%.1f%%", cpuUsage)
    }

    var portsFormatted: String {
        if ports.isEmpty {
            return "—"
        }
        return ports.map(String.init).joined(separator: ", ")
    }
}
