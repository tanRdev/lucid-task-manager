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
        VStack(alignment: .leading, spacing: 0) {
            // Metrics Row - compact horizontal display
            metricsRow
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

            Rectangle()
                .fill(LucidTheme.divider)
                .frame(height: 1)

            // Filters Section
            VStack(alignment: .leading, spacing: 0) {
                Text("FILTERS")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                VStack(spacing: 0) {
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
                .padding(.horizontal, 12)
            }

            // Active Ports Section
            if !monitor.activePorts.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("PORTS")
                        .font(.system(size: 10, weight: .semibold, design: .default))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(monitor.activePorts, id: \.self) { port in
                                PortFilterRow(
                                    port: port,
                                    isActive: monitor.selectedFilter == .port(port),
                                    onSelect: { monitor.selectedFilter = .port(port) },
                                    onKill: { portToKill = port }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .frame(maxHeight: 160)
                }
            }

            Spacer()

            Rectangle()
                .fill(LucidTheme.divider)
                .frame(height: 1)

            // Footer - clean minimal row
            HStack(spacing: 10) {
                if monitor.isRunning {
                    PulsingStatusDot()
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                }

                Text(monitor.isRunning ? "Live" : "Paused")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(monitor.isRunning ? LucidTheme.statusSuccess : .secondary)

                Spacer()

                Text(systemInfoString)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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

    // MARK: - Metrics Row (compact inline display)
    private var metricsRow: some View {
        HStack(spacing: 16) {
            MetricItem(label: "CPU", value: String(format: "%.1f%%", monitor.stats.cpuUsage))
            MetricItem(label: "MEM", value: String(format: "%.1f%%", monitor.stats.memoryUsage))
            MetricItem(label: "PROC", value: "\(monitor.filterCounts.total)")
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
        let cpuCores = ProcessInfo.processInfo.activeProcessorCount
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let ramGB = String(format: "%.0f", Double(totalRAM) / (1024 * 1024 * 1024))
        return "\(version.majorVersion).\(version.minorVersion) • \(cpuCores) cores • \(ramGB) GB"
    }
}

// MARK: - Metric Item (compact inline metric)
struct MetricItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
