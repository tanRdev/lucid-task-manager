import SwiftUI

struct SidebarView: View {
    @Environment(ProcessMonitor.self) var monitor

    var body: some View {
        VStack(spacing: 16) {
            // Metrics Row
            MetricsRowView()

            Divider()

            // Filters Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Filters")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    FilterButton(
                        label: "All Processes",
                        icon: "square.grid.2x2",
                        count: monitor.processes.count
                    )

                    FilterButton(
                        label: "System",
                        icon: "gearshape.fill",
                        count: monitor.processes.filter { $0.safety == .system }.count,
                        isActive: true
                    )

                    FilterButton(
                        label: "User",
                        icon: "person.fill",
                        count: monitor.processes.filter { $0.safety == .user }.count
                    )

                    FilterButton(
                        label: "Unknown",
                        icon: "questionmark.circle.fill",
                        count: monitor.processes.filter { $0.safety == .unknown }.count
                    )
                }
                .padding(.horizontal)
            }

            Spacer()

            // Footer
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Status")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(monitor.isRunning ? "Monitoring" : "Idle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
    }
}
