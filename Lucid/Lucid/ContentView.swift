import SwiftUI

struct ContentView: View {
    @Environment(ProcessMonitor.self) var monitor

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .preferredColorScheme(.dark)
    }
}

struct DetailView: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var searchText = ""
    @State private var sortOrder: [KeyPathComparator<LucidProcess>] = [
        .init(\.cpuUsage, order: .reverse)
    ]
    @State private var selectedFilter: FilterCategory = .all
    @State private var killTarget: LucidProcess?

    enum FilterCategory {
        case all
        case system
        case user
        case unknown
    }

    var filteredProcesses: [LucidProcess] {
        var result = monitor.processes

        // Apply safety filter
        switch selectedFilter {
        case .all:
            break
        case .system:
            result = result.filter { $0.safety == .system }
        case .user:
            result = result.filter { $0.safety == .user }
        case .unknown:
            result = result.filter { $0.safety == .unknown }
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
                selectedFilter: $selectedFilter
            )

            Table(filteredProcesses, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { process in
                    HStack(spacing: 8) {
                        SafetyDot(safety: process.safety)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(process.name)
                                .font(.system(.body, design: .monospaced))
                            Text(process.description)
                                .font(.system(.caption, design: .default))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                TableColumn("PID", value: \.pid) { process in
                    Text("\(process.pid)")
                        .font(.system(.body, design: .monospaced))
                }

                TableColumn("CPU", value: \.cpuUsage) { process in
                    Text(process.cpuFormatted)
                        .font(.system(.body, design: .monospaced))
                }

                TableColumn("Memory", value: \.memoryBytes) { process in
                    Text(process.memoryFormatted)
                        .font(.system(.body, design: .monospaced))
                }

                TableColumn("Path", value: \.exePath) { process in
                    Text(process.exePath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
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
                isPresented: .constant(killTarget != nil),
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
    }
}
