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
    @State private var multiKillTargets: [LucidProcess] = []
    @State private var selection = Set<LucidProcess.ID>()
    @State private var killError: String?

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

            Table(filteredProcesses, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { process in
                    Text(process.name)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TableColumn("Tag") { process in
                    HStack(spacing: 4) {
                        Image(systemName: process.safety.systemImage)
                            .font(.system(size: 10))
                            .foregroundStyle(process.safety.color)
                        Text(process.safety.label)
                            .font(.system(size: LucidTheme.fontSizeXS, weight: .medium))
                            .foregroundStyle(process.safety.color)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(process.safety.color.opacity(0.15))
                    .clipShape(Capsule())
                }
                .width(min: 80, ideal: 100)

                TableColumn("Description", value: \.description) { process in
                    Text(process.description)
                        .font(.system(.body, design: .default))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TableColumn("CPU", value: \.cpuUsage) { process in
                    Text(process.cpuFormatted)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TableColumn("Memory", value: \.memoryBytes) { process in
                    Text(process.memoryFormatted)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                TableColumn("Path", value: \.exePath) { process in
                    Text(process.exePath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .contextMenu(forSelectionType: LucidProcess.ID.self) { selectedIDs in
                if selectedIDs.isEmpty {
                    EmptyView()
                } else if selectedIDs.count == 1,
                          let id = selectedIDs.first,
                          let process = filteredProcesses.first(where: { $0.id == id }) {
                    // Single selection - show all options
                    Button(role: .destructive) {
                        killTarget = process
                    } label: {
                        Label("Kill Process", systemImage: "xmark.circle")
                    }

                    Divider()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(process.exePath, forType: .string)
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }

                    Button {
                        NSWorkspace.shared.selectFile(process.exePath, inFileViewerRootedAtPath: "")
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                } else if selectedIDs.count > 1 {
                    // Multiple selection - only show kill
                    Button(role: .destructive) {
                        multiKillTargets = filteredProcesses.filter { selectedIDs.contains($0.id) }
                    } label: {
                        Label("Kill \(selectedIDs.count) Processes", systemImage: "xmark.circle")
                    }
                }
            }
            .confirmationDialog(
                killTarget != nil ? "Kill Process" : "Kill Processes",
                isPresented: Binding(
                    get: { killTarget != nil || !multiKillTargets.isEmpty },
                    set: { if !$0 {
                        killTarget = nil
                        multiKillTargets = []
                    }}
                ),
                presenting: killTarget ?? multiKillTargets.first
            ) { process in
                Button("Kill", role: .destructive) {
                    var errors: [String] = []
                    if let single = killTarget {
                        if case .failure(let error) = monitor.killProcess(single) {
                            errors.append("\(single.name): \(error.localizedDescription)")
                        }
                        killTarget = nil
                    } else {
                        for target in multiKillTargets {
                            if case .failure(let error) = monitor.killProcess(target) {
                                errors.append("\(target.name): \(error.localizedDescription)")
                            }
                        }
                        multiKillTargets = []
                    }
                    if !errors.isEmpty {
                        killError = errors.joined(separator: "\n")
                    }
                    selection.removeAll()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        monitor.refresh()
                    }
                }
            } message: { process in
                if let single = killTarget {
                    Text("Are you sure you want to kill \(single.name) (PID: \(single.pid))?")
                } else {
                    Text("Are you sure you want to kill \(multiKillTargets.count) processes?")
                }
            }
        }
        .background(LucidTheme.backgroundDark)
        .toolbar(.hidden)
        .alert("Kill Failed", isPresented: Binding(
            get: { killError != nil },
            set: { if !$0 { killError = nil } }
        )) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
    }
}
