import SwiftUI

struct SidebarView: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var portToKill: UInt16?
    @State private var killError: String?

    private var killErrorBinding: Binding<Bool> {
        Binding(
            get: { killError != nil },
            set: { if !$0 { killError = nil } }
        )
    }

    private var portKillBinding: Binding<Bool> {
        Binding(
            get: { portToKill != nil },
            set: { if !$0 { portToKill = nil } }
        )
    }

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
                        count: monitor.filterCounts.total,
                        isActive: monitor.selectedFilter == .all,
                        action: { monitor.selectedFilter = .all }
                    )

                    FilterButton(
                        label: "System",
                        icon: "gearshape.fill",
                        count: monitor.filterCounts.system,
                        isActive: monitor.selectedFilter == .system,
                        action: { monitor.selectedFilter = .system }
                    )

                    FilterButton(
                        label: "User",
                        icon: "person.fill",
                        count: monitor.filterCounts.user,
                        isActive: monitor.selectedFilter == .user,
                        action: { monitor.selectedFilter = .user }
                    )

                    FilterButton(
                        label: "Unknown",
                        icon: "questionmark.circle.fill",
                        count: monitor.filterCounts.unknown,
                        isActive: monitor.selectedFilter == .unknown,
                        action: { monitor.selectedFilter = .unknown }
                    )
                }
                .padding(.horizontal)
            }

            // Active Ports Section
            if !monitor.activePorts.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Ports")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(monitor.activePorts, id: \.self) { port in
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
        .background(LucidTheme.backgroundSecondary)
        .confirmationDialog(
            "Kill Processes",
            isPresented: portKillBinding,
            presenting: portToKill
        ) { port in
            killButton(for: port)
        } message: { port in
            killDialogMessage(for: port)
        }
        .alert("Kill Failed", isPresented: killErrorBinding) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
    }

    private func killButton(for port: UInt16) -> some View {
        Button("Kill All Processes on Port \(port)", role: .destructive) {
            let processesToKill = monitor.processes.filter { $0.ports.contains(port) }
            if case .failure(let error) = monitor.killProcesses(processesToKill) {
                killError = error.localizedDescription
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    monitor.refresh()
                }
            }
            portToKill = nil
        }
    }

    private func killDialogMessage(for port: UInt16) -> some View {
        let processCount = monitor.processes.filter { $0.ports.contains(port) }.count
        return Text("Are you sure you want to kill all \(processCount) process(es) using port \(port)?")
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
