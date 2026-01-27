import Foundation

struct SystemStats: Hashable {
    let cpuUsage: Double
    let memoryUsage: Double
    let memoryBytes: UInt64
    let totalMemoryBytes: UInt64
    let timestamp: Date

    // History arrays for sparklines (12 entries)
    var cpuHistory: [Double] = []
    var memoryHistory: [Double] = []

    var memoryMB: Double {
        Double(memoryBytes) / (1024 * 1024)
    }

    var totalMemoryMB: Double {
        Double(totalMemoryBytes) / (1024 * 1024)
    }

    var totalMemoryGB: Double {
        totalMemoryMB / 1024
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

    var memoryPercentFormatted: String {
        String(format: "%.1f%%", memoryUsage)
    }
}
