import SwiftUI

struct MetricsRowView: View {
    @Environment(ProcessMonitor.self) var monitor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                MetricCardView(
                    label: "CPU",
                    value: String(format: "%.1f%%", monitor.stats.cpuUsage),
                    icon: "cpu",
                    color: Color(red: 1.0, green: 0.35, blue: 0.0),
                    history: monitor.stats.cpuHistory
                )

                MetricCardView(
                    label: "Memory",
                    value: String(format: "%.1f%%", monitor.stats.memoryUsage),
                    icon: "memorychip",
                    color: Color(red: 0.2, green: 0.8, blue: 0.2),
                    history: monitor.stats.memoryHistory
                )

                MetricCardView(
                    label: "Processes",
                    value: "\(monitor.processes.count)",
                    icon: "square.grid.2x2",
                    color: Color(red: 0.2, green: 0.6, blue: 1.0),
                    history: []
                )

                MetricCardView(
                    label: "Memory GB",
                    value: String(format: "%.1f/%.1f", monitor.stats.memoryMB / 1024, monitor.stats.totalMemoryGB),
                    icon: "internaldrive",
                    color: Color(red: 1.0, green: 0.6, blue: 0.2),
                    history: []
                )
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MetricsRowView()
        .environment(ProcessMonitor())
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
}
