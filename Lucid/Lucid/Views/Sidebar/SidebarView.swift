import SwiftUI

struct SidebarView: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var portToKill: UInt16?
    @State private var killError: String?
    @State private var riskyKillTargets: [LucidProcess] = []
    @State private var forceQuitTargets: [LucidProcess] = []

    private var killErrorBinding: Binding<Bool> {
        Binding(
            get: { killError != nil },
            set: { if !$0 { killError = nil } }
        )
    }

    private var riskyKillBinding: Binding<Bool> {
        Binding(
            get: { !riskyKillTargets.isEmpty },
            set: { if !$0 { riskyKillTargets = [] } }
        )
    }

    private var forceQuitBinding: Binding<Bool> {
        Binding(
            get: { !forceQuitTargets.isEmpty },
            set: { if !$0 { forceQuitTargets = [] } }
        )
    }

    private var portKillBinding: Binding<Bool> {
        Binding(
            get: { portToKill != nil },
            set: { if !$0 { portToKill = nil } }
        )
    }

    private var selection: Binding<FilterCategory?> {
        Binding(
            get: { monitor.selectedFilter },
            set: { monitor.selectedFilter = $0 ?? .all }
        )
    }

    var body: some View {
        List(selection: selection) {
            Section("Filters") {
                filterRow(
                    title: "All Processes",
                    icon: "square.grid.2x2",
                    count: monitor.filterCounts.total
                )
                .tag(FilterCategory.all)

                filterRow(
                    title: "System",
                    icon: "gearshape.fill",
                    count: monitor.filterCounts.system
                )
                .tag(FilterCategory.system)

                filterRow(
                    title: "User",
                    icon: "person.fill",
                    count: monitor.filterCounts.user
                )
                .tag(FilterCategory.user)

                filterRow(
                    title: "Unknown",
                    icon: "questionmark.circle.fill",
                    count: monitor.filterCounts.unknown
                )
                .tag(FilterCategory.unknown)
            }

            if !monitor.activePorts.isEmpty {
                Section("Ports") {
                    ForEach(monitor.activePorts, id: \.self) { port in
                        PortFilterRow(
                            port: port,
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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(monitor.isRunning ? LucidTheme.statusSuccess : .secondary)

                    Spacer(minLength: 0)
                }

                Text(systemInfoString)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
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
                Button(
                    "Kill \(LucidFormat.count(killable.count)) Process\(killable.count == 1 ? "" : "es")",
                    role: .destructive
                ) {
                    portToKill = nil
                    runKill(killable)
                }
                Button("Cancel", role: .cancel) { portToKill = nil }
            }
        } message: { port in
            portKillMessage(for: port)
        }
        .confirmationDialog(
            "Confirm Risky Termination",
            isPresented: riskyKillBinding
        ) {
            Button("Kill Anyway", role: .destructive) {
                let targets = riskyKillTargets
                riskyKillTargets = []
                runKill(targets, confirmedRisky: true)
            }
            Button("Cancel", role: .cancel) { riskyKillTargets = [] }
        } message: {
            Text(riskyKillMessage)
        }
        .confirmationDialog(
            "Process Still Running",
            isPresented: forceQuitBinding
        ) {
            Button("Force Quit (SIGKILL)", role: .destructive) {
                let targets = forceQuitTargets
                forceQuitTargets = []
                runKill(targets, confirmedRisky: true, force: true)
            }
            Button("Cancel", role: .cancel) { forceQuitTargets = [] }
        } message: {
            Text(forceQuitMessage)
        }
        .alert("Kill Failed", isPresented: killErrorBinding) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
        .navigationTitle("Lucid")
    }

    private func filterRow(title: String, icon: String, count: Int) -> some View {
        Label {
            HStack(spacing: 8) {
                Text(title)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(verbatim: LucidFormat.count(count))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var statusLabel: String {
        if monitor.isPausedForInactivity {
            return "Paused while inactive"
        }
        return monitor.isRunning ? "Live" : "Paused"
    }

    private var metricsRow: some View {
        HStack(spacing: 14) {
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
                value: LucidFormat.count(monitor.filterCounts.total),
                threshold: 500,
                currentValue: Double(monitor.filterCounts.total)
            )
            Spacer(minLength: 0)
        }
    }

    private func runKill(
        _ targets: [LucidProcess],
        confirmedRisky: Bool = false,
        force: Bool = false
    ) {
        Task { @MainActor in
            let result = await monitor.killProcesses(
                targets,
                confirmedRisky: confirmedRisky,
                force: force
            )
            switch result {
            case .success:
                monitor.refresh()
            case .failure(let error):
                if !error.riskyTargets.isEmpty {
                    riskyKillTargets = error.riskyTargets
                } else if !error.survivors.isEmpty {
                    forceQuitTargets = error.survivors
                } else {
                    killError = error.localizedDescription
                }
            }
        }
    }

    private var riskyKillMessage: String {
        let lines = riskyKillTargets.prefix(8).map { process -> String in
            let risk = ProcessMonitor.riskFactor(for: process) ?? "unverified"
            return "• \(process.name) (PID \(LucidFormat.pid(process.pid))) — \(risk)"
        }
        var message = "These processes could not be classified with confidence:\n"
            + lines.joined(separator: "\n")
        if riskyKillTargets.count > 8 {
            message += "\n• …and \(LucidFormat.count(riskyKillTargets.count - 8)) more"
        }
        message += "\n\nTerminating them may destabilize your system. Kill anyway?"
        return message
    }

    private var forceQuitMessage: String {
        let lines = forceQuitTargets.prefix(8).map {
            "• \($0.name) (PID \(LucidFormat.pid($0.pid)))"
        }
        var message = "Still running after the terminate request:\n" + lines.joined(separator: "\n")
        message += "\n\nForce quitting skips graceful shutdown and may lose unsaved data."
        return message
    }

    private func portKillMessage(for port: UInt16) -> Text {
        let killable = monitor.killableProcesses(onPort: port)
        let protected = monitor.protectedProcesses(onPort: port)
        var lines: [String] = []
        if killable.isEmpty {
            lines.append("No unprotected processes are listening on port \(LucidFormat.port(port)).")
        } else {
            lines.append("Will terminate:")
            lines.append(contentsOf: killable.prefix(8).map {
                "• \($0.name) (PID \(LucidFormat.pid($0.pid)))"
            })
            if killable.count > 8 {
                lines.append("• …and \(LucidFormat.count(killable.count - 8)) more")
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
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(statusColor)
        }
        .accessibilityElement(children: .combine)
    }
}
