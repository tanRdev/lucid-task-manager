import SwiftUI

struct SidebarView: View {
    @Environment(ProcessMonitor.self) var monitor
    @Environment(ProcessStore.self) var processStore
    @Environment(FilterState.self) var filterState

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
            // Metrics Row - now with history
            MetricsRowView()

            Divider()

            // Filters Section
            FiltersSection()

            // Active Ports Section - now uses pre-computed portProcessMap
            if !processStore.activePorts.isEmpty {
                Divider()
                ActivePortsSection(portToKill: $portToKill)
            }

            Spacer()

            // Footer
            SidebarFooter()
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
            let processesToKill = processStore.processes.filter { $0.ports.contains(port) }
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
        let processCount = processStore.processes(for: port).count
        return Text("Are you sure you want to kill all \(processCount) process(es) using port \(port)?")
    }
}

// MARK: - Filters Section

struct FiltersSection: View {
    @Environment(ProcessStore.self) var processStore
    @Environment(FilterState.self) var filterState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filters")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                FilterButton(
                    label: "All Processes",
                    icon: "square.grid.2x2",
                    count: processStore.filterCounts.total,
                    isActive: filterState.selectedFilter == .all,
                    action: { filterState.applyFilter(.all) }
                )

                FilterButton(
                    label: "System",
                    icon: "gearshape.fill",
                    count: processStore.filterCounts.system,
                    isActive: filterState.selectedFilter == .system,
                    action: { filterState.applyFilter(.system) }
                )

                FilterButton(
                    label: "User",
                    icon: "person.fill",
                    count: processStore.filterCounts.user,
                    isActive: filterState.selectedFilter == .user,
                    action: { filterState.applyFilter(.user) }
                )

                FilterButton(
                    label: "Unknown",
                    icon: "questionmark.circle.fill",
                    count: processStore.filterCounts.unknown,
                    isActive: filterState.selectedFilter == .unknown,
                    action: { filterState.applyFilter(.unknown) }
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Active Ports Section

struct ActivePortsSection: View {
    @Environment(ProcessStore.self) var processStore
    @Environment(FilterState.self) var filterState
    @Binding var portToKill: UInt16?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Ports")
                .font(.headline)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(processStore.activePorts, id: \.self) { port in
                        PortFilterRow(
                            port: port,
                            processCount: processStore.processes(for: port).count,
                            isActive: filterState.selectedFilter == .port(port),
                            onSelect: { filterState.applyFilter(.port(port)) },
                            onKill: { portToKill = port }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)
        }
    }
}

// MARK: - Sidebar Footer

struct SidebarFooter: View {
    @Environment(ProcessMonitor.self) var monitor

    var body: some View {
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

    private var systemInfoString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let cpuCores = ProcessInfo.processInfo.activeProcessorCount
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        let ramGB = String(format: "%.0f", Double(totalRAM) / (1024 * 1024 * 1024))
        return "\(osVersion) \u{2022} \(cpuCores) cores \u{2022} \(ramGB) GB RAM"
    }
}