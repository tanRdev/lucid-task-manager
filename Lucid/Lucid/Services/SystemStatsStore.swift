import Foundation
import Observation

@Observable
@MainActor
final class SystemStatsStore {
    // MARK: - Observable State
    var stats: SystemStats = SystemStats(
        cpuUsage: 0,
        memoryUsage: 0,
        memoryBytes: 0,
        totalMemoryBytes: 0,
        timestamp: Date()
    )

    private(set) var cpuHistory: [Double] = []
    private(set) var memoryHistory: [Double] = []
    private(set) var lastUpdate: Date = Date()

    // MARK: - Constants
    private let maxHistoryEntries = 12

    // MARK: - Public Methods

    func updateStats(_ newStats: SystemStats) {
        stats = newStats
        lastUpdate = Date()

        // Update histories
        cpuHistory.append(newStats.cpuUsage)
        memoryHistory.append(newStats.memoryUsage)

        // Trim to max entries
        if cpuHistory.count > maxHistoryEntries {
            cpuHistory.removeFirst(cpuHistory.count - maxHistoryEntries)
        }
        if memoryHistory.count > maxHistoryEntries {
            memoryHistory.removeFirst(memoryHistory.count - maxHistoryEntries)
        }
    }

    // MARK: - Calculated Properties

    var averageCPU: Double {
        guard !cpuHistory.isEmpty else { return 0 }
        return cpuHistory.reduce(0, +) / Double(cpuHistory.count)
    }

    var peakMemoryUsage: Double {
        memoryHistory.max() ?? 0
    }

    var averageMemoryUsage: Double {
        guard !memoryHistory.isEmpty else { return 0 }
        return memoryHistory.reduce(0, +) / Double(memoryHistory.count)
    }

    // MARK: - Formatted Values

    var formattedCPU: String {
        String(format: "%.1f%%", stats.cpuUsage)
    }

    var formattedMemory: String {
        String(format: "%.1f%%", stats.memoryUsage)
    }

    var formattedMemoryGB: String {
        String(format: "%.1f/%.1f", stats.memoryMB / 1024, stats.totalMemoryGB)
    }
}