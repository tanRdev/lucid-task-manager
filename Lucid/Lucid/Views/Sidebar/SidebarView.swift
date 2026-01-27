import SwiftUI

struct SidebarView: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var portToKill: UInt16?

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
                        count: monitor.processes.count,
                        isActive: monitor.selectedFilter == .all,
                        action: { monitor.selectedFilter = .all }
                    )

                    FilterButton(
                        label: "System",
                        icon: "gearshape.fill",
                        count: monitor.processes.filter { $0.safety == .system }.count,
                        isActive: monitor.selectedFilter == .system,
                        action: { monitor.selectedFilter = .system }
                    )

                    FilterButton(
                        label: "User",
                        icon: "person.fill",
                        count: monitor.processes.filter { $0.safety == .user }.count,
                        isActive: monitor.selectedFilter == .user,
                        action: { monitor.selectedFilter = .user }
                    )

                    FilterButton(
                        label: "Unknown",
                        icon: "questionmark.circle.fill",
                        count: monitor.processes.filter { $0.safety == .unknown }.count,
                        isActive: monitor.selectedFilter == .unknown,
                        action: { monitor.selectedFilter = .unknown }
                    )
                }
                .padding(.horizontal)
            }

            // Active Ports Section
            if !activePorts.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Ports")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(activePorts, id: \.self) { port in
                                PortFilterRow(
                                    port: port,
                                    processCount: monitor.processes.filter { $0.ports.contains(port) }.count,
                                    isActive: monitor.selectedFilter == .port(port),
                                    onSelect: { monitor.selectedFilter = .port(port) },
                                    onKill: { portToKill = port }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 200)
                }
            }

            Spacer()

            // Footer
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack(spacing: 8) {
                    if monitor.isRunning {
                        PulsingStatusDot()
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 8, height: 8)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(monitor.isRunning ? "Monitoring" : "Idle")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(monitor.isRunning ? Color.green : .secondary)
                        Text(systemInfoString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.1))
        .confirmationDialog(
            "Kill Processes",
            isPresented: Binding(
                get: { portToKill != nil },
                set: { if !$0 { portToKill = nil } }
            ),
            presenting: portToKill
        ) { port in
            Button("Kill All Processes on Port \(port)", role: .destructive) {
                let processesToKill = monitor.processes.filter { $0.ports.contains(port) }
                for process in processesToKill {
                    _ = monitor.killProcess(process)
                }
                portToKill = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    monitor.refresh()
                }
            }
        } message: { port in
            let processCount = monitor.processes.filter { $0.ports.contains(port) }.count
            Text("Are you sure you want to kill all \(processCount) process(es) using port \(port)?")
        }
    }

    private var activePorts: [UInt16] {
        Array(Set(monitor.processes.flatMap(\.ports))).sorted()
    }

    private var systemInfoString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let cpuCores = ProcessInfo.processInfo.activeProcessorCount
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let ramGB = String(format: "%.0f", Double(totalRAM) / (1024 * 1024 * 1024))
        return "\(osVersion) \u{2022} \(cpuCores) cores \u{2022} \(ramGB) GB RAM"
    }
}
