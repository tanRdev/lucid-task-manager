import SwiftUI

struct ContentView: View {
    @Environment(ProcessMonitor.self) var monitor
    @AppStorage("appTheme") private var appTheme: String = "system"

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .preferredColorScheme(colorScheme)
    }
}

struct DetailView: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var searchText = ""
    @State private var sortOrder: [KeyPathComparator<LucidProcess>] = [
        .init(\.cpuUsage, order: .reverse)
    ]
    @State private var killTarget: LucidProcess?
    @State private var hoveredPID: pid_t?

    var filteredProcesses: [LucidProcess] {
        var result = monitor.processes

        // Apply filter
        switch monitor.selectedFilter {
        case .all:
            break
        case .system:
            result = result.filter { $0.safety == .system }
        case .user:
            result = result.filter { $0.safety == .user }
        case .unknown:
            result = result.filter { $0.safety == .unknown }
        case .port(let port):
            result = result.filter { $0.ports.contains(port) }
        }

        // Apply search
        if !searchText.isEmpty {
            result = result.filter { process in
                process.name.localizedCaseInsensitiveContains(searchText) ||
                process.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sort
        result.sort(using: sortOrder)

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                processCount: filteredProcesses.count,
                searchText: $searchText,
                selectedFilter: Binding(
                    get: { monitor.selectedFilter },
                    set: { monitor.selectedFilter = $0 }
                )
            )

            Table(filteredProcesses, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { process in
                    HStack(spacing: 8) {
                        Text(process.name)
                            .font(.system(.body, design: .monospaced))
                        SafetyTag(safety: process.safety)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering { hoveredPID = process.pid }
                        else if hoveredPID == process.pid { hoveredPID = nil }
                    }
                }

                TableColumn("Description", value: \.description) { process in
                    Text(process.description)
                        .font(.system(.body, design: .default))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering { hoveredPID = process.pid }
                            else if hoveredPID == process.pid { hoveredPID = nil }
                        }
                }

                TableColumn("CPU", value: \.cpuUsage) { process in
                    Text(process.cpuFormatted)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering { hoveredPID = process.pid }
                            else if hoveredPID == process.pid { hoveredPID = nil }
                        }
                }

                TableColumn("Memory", value: \.memoryBytes) { process in
                    Text(process.memoryFormatted)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering { hoveredPID = process.pid }
                            else if hoveredPID == process.pid { hoveredPID = nil }
                        }
                }

                TableColumn("Port") { process in
                    Text(process.portsFormatted)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(process.ports.isEmpty ? .tertiary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering { hoveredPID = process.pid }
                            else if hoveredPID == process.pid { hoveredPID = nil }
                        }
                }
                .width(min: 60, ideal: 80)

                TableColumn("Path", value: \.exePath) { process in
                    Text(process.exePath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            if hovering { hoveredPID = process.pid }
                            else if hoveredPID == process.pid { hoveredPID = nil }
                        }
                }

                TableColumn("") { process in
                    HoverKillButton(process: process, isRowHovered: hoveredPID == process.pid) {
                        killTarget = process
                    }
                }
                .width(40)
            }
            .contextMenu(forSelectionType: LucidProcess.ID.self) { selection in
                if let processID = selection.first,
                   let process = filteredProcesses.first(where: { $0.id == processID }) {
                    Button(role: .destructive) {
                        killTarget = process
                    } label: {
                        Label("Kill Process", systemImage: "xmark.circle")
                    }
                }
            }
            .confirmationDialog(
                "Kill Process",
                isPresented: Binding(
                    get: { killTarget != nil },
                    set: { if !$0 { killTarget = nil } }
                ),
                presenting: killTarget
            ) { process in
                Button("Kill", role: .destructive) {
                    _ = monitor.killProcess(process)
                    killTarget = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        monitor.refresh()
                    }
                }
            } message: { process in
                Text("Are you sure you want to kill \(process.name) (PID: \(process.pid))?")
            }
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.07))
        .toolbar(.hidden)
    }
}
