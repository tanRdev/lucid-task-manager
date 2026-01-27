import SwiftUI

struct MetricsRowView: View {
    @Environment(ProcessMonitor.self) var monitor

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            MetricCardView(
                label: "CPU",
                value: String(format: "%.1f%%", monitor.stats.cpuUsage),
                icon: "cpu",
                color: LucidTheme.metricCPU,
                history: []
            )

            MetricCardView(
                label: "Memory",
                value: String(format: "%.1f%%", monitor.stats.memoryUsage),
                icon: "memorychip",
                color: LucidTheme.metricMemory,
                history: []
            )

            MetricCardView(
                label: "Processes",
                value: "\(monitor.filterCounts.total)",
                icon: "square.grid.2x2",
                color: LucidTheme.metricProcesses,
                history: []
            )

            MetricCardView(
                label: "Memory GB",
                value: String(format: "%.1f/%.1f", monitor.stats.memoryMB / 1024, monitor.stats.totalMemoryGB),
                icon: "internaldrive",
                color: LucidTheme.metricDisk,
                history: []
            )
        }
        .padding(.horizontal)
    }
}
