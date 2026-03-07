import SwiftUI

struct MetricsRowView: View {
    @Environment(ProcessStore.self) var processStore
    @Environment(SystemStatsStore.self) var statsStore

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            MetricCardView(
                label: "CPU",
                value: statsStore.formattedCPU,
                icon: "cpu",
                color: LucidTheme.metricCPU,
                history: statsStore.cpuHistory
            )

            MetricCardView(
                label: "Memory",
                value: statsStore.formattedMemory,
                icon: "memorychip",
                color: LucidTheme.metricMemory,
                history: statsStore.memoryHistory
            )

            MetricCardView(
                label: "Processes",
                value: "\(processStore.filterCounts.total)",
                icon: "square.grid.2x2",
                color: LucidTheme.metricProcesses,
                history: []
            )

            MetricCardView(
                label: "Memory GB",
                value: statsStore.formattedMemoryGB,
                icon: "internaldrive",
                color: LucidTheme.metricDisk,
                history: []
            )
        }
        .padding(.horizontal)
    }
}