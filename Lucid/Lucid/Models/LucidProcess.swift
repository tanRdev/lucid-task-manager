import Foundation

struct LucidProcess: Identifiable, Hashable, Comparable {
    let id = UUID()
    let pid: pid_t
    let name: String
    let description: String
    let cpuUsage: Double
    let memoryBytes: UInt64
    let safety: Safety
    let exePath: String
    let ports: [UInt16]

    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }

    static func == (lhs: LucidProcess, rhs: LucidProcess) -> Bool {
        lhs.pid == rhs.pid
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
            return "-"
        }
        return ports.map(String.init).joined(separator: ", ")
    }
}
