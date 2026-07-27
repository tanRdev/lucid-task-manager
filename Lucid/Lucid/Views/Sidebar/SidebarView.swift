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
        List(selection: Binding(
            get: { monitor.selectedFilter },
            set: { monitor.selectedFilter = $0 }
        )) {
            Section("Filters") {
                FilterButton(
                    label: "All Processes",
                    icon: "square.grid.2x2",
                    count: monitor.filterCounts.total,
                    isActive: monitor.selectedFilter == .all,
                    action: { monitor.selectedFilter = .all }
                )
                .tag(FilterCategory.all)

                FilterButton(
                    label: "System",
                    icon: "gearshape.fill",
                    count: monitor.filterCounts.system,
                    isActive: monitor.selectedFilter == .system,
                    action: { monitor.selectedFilter = .system }
                )
                .tag(FilterCategory.system)

                FilterButton(
                    label: "User",
                    icon: "person.fill",
                    count: monitor.filterCounts.user,
                    isActive: monitor.selectedFilter == .user,
                    action: { monitor.selectedFilter = .user }
                )
                .tag(FilterCategory.user)

                FilterButton(
                    label: "Unknown",
                    icon: "questionmark.circle.fill",
                    count: monitor.filterCounts.unknown,
                    isActive: monitor.selectedFilter == .unknown,
                    action: { monitor.selectedFilter = .unknown }
                )
                .tag(FilterCategory.unknown)
            }

            if !monitor.activePorts.isEmpty {
                Section("Ports") {
                    ForEach(monitor.activePorts, id: \.self) { port in
                        PortFilterRow(
                            port: port,
                            isActive: monitor.selectedFilter == .port(port),
                            onSelect: { monitor.selectedFilter = .port(port) },
                            onKill: { portToKill = port }
                        )
                        .tag(FilterCategory.port(port))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                metricsRow

                HStack(spacing: 8) {
                    PulsingStatusDot()

                    Text(statusLabel)
                        .font(.caption)
                        .foregroundStyle(monitor.isRunning ? LucidTheme.statusSuccess : .secondary)

                    Spacer()
                }

                Text(systemInfoString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
        }
        .confirmationDialog(
            "Kill Processes on Port",
            isPresented: portKillBinding,
            presenting: portToKill
        ) { port in
            let killable = monitor.killableProcesses(onPort: port)
            if killable.isEmpty {
                Button("OK", role: .cancel) { portToKill = nil }
            } else {
                Button("Kill \(killable.count) Process\(killable.count == 1 ? "" : "es")", role: .destructive) {
                    if case .failure(let error) = monitor.killProcesses(killable) {
                        killError = error.localizedDescription
                    } else {
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(500))
                            monitor.refresh()
                        }
                    }
                    portToKill = nil
                }
                Button("Cancel", role: .cancel) { portToKill = nil }
            }
        } message: { port in
            portKillMessage(for: port)
        }
        .alert("Kill Failed", isPresented: killErrorBinding) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
        .navigationTitle("Lucid")
    }

    private var statusLabel: String {
        if monitor.isPausedForInactivity {
            return "Paused while inactive"
        }
        return monitor.isRunning ? "Live" : "Paused"
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            MetricItem(
                label: "CPU",
                value: String(format: "%.0f%%", monitor.stats.cpuUsage),
                threshold: 80.0,
                currentValue: monitor.stats.cpuUsage
            )
            MetricItem(
                label: "Mem",
                value: String(format: "%.0f%%", monitor.stats.memoryUsage),
                threshold: 80.0,
                currentValue: monitor.stats.memoryUsage
            )
            MetricItem(
                label: "Proc",
                value: "\(monitor.filterCounts.total)",
                threshold: 500,
                currentValue: Double(monitor.filterCounts.total)
            )
        }
    }

    private func portKillMessage(for port: UInt16) -> Text {
        let killable = monitor.killableProcesses(onPort: port)
        let protected = monitor.protectedProcesses(onPort: port)
        var lines: [String] = []
        if killable.isEmpty {
            lines.append("No unprotected processes are listening on port \(port).")
        } else {
            lines.append("Will terminate:")
            lines.append(contentsOf: killable.prefix(8).map { "• \($0.name) (PID \($0.pid))" })
            if killable.count > 8 {
                lines.append("• …and \(killable.count - 8) more")
            }
        }
        if !protected.isEmpty {
            lines.append("Protected (skipped): \(protected.map(\.name).joined(separator: ", "))")
        }
        return Text(lines.joined(separator: "\n"))
    }

    private var systemInfoString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let cpuCores = ProcessInfo.processInfo.activeProcessorCount
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let ramGB = String(format: "%.0f", Double(totalRAM) / (1024 * 1024 * 1024))
        return "macOS \(version.majorVersion).\(version.minorVersion) · \(cpuCores) cores · \(ramGB) GB"
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let threshold: Double
    let currentValue: Double

    private var statusColor: Color {
        if currentValue >= threshold {
            return LucidTheme.statusCritical
        } else if currentValue >= threshold * 0.7 {
            return LucidTheme.statusWarning
        }
        return .primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(statusColor)
        }
    }
}
