import Foundation

/// Unlocalized numeric strings for ports, PIDs, and counts.
/// Prefer these over `Text("\(n)")`, which applies locale grouping (e.g. `8,265`).
enum LucidFormat {
    static func port(_ port: UInt16) -> String {
        String(port)
    }

    static func ports(_ ports: [UInt16]) -> String {
        if ports.isEmpty { return "—" }
        return ports.map(String.init).joined(separator: ", ")
    }

    static func pid(_ pid: pid_t) -> String {
        String(pid)
    }

    static func count(_ value: Int) -> String {
        String(value)
    }

    static func userID(_ uid: uid_t) -> String {
        String(uid)
    }
}
