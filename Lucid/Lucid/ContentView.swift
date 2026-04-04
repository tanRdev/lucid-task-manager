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
        HStack(spacing: 0) {
            // Sidebar with fixed width
            SidebarView()
                .frame(width: 240)
                .background(LucidTheme.backgroundBase)

            // Single solid line separator (no gradient/shadow effects)
            Rectangle()
                .fill(LucidTheme.divider)
                .frame(width: 1)

            // Detail view fills remaining space
            DetailView()
                .ignoresSafeArea(.container, edges: .top)
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

    private var filterBinding: Binding<FilterCategory> {
        Binding(
            get: { monitor.selectedFilter },
            set: { monitor.selectedFilter = $0 }
        )
    }

    private var killErrorBinding: Binding<Bool> {
        Binding(
            get: { killError != nil },
            set: { if !$0 { killError = nil } }
        )
    }

    private var killConfirmationBinding: Binding<Bool> {
        Binding(
            get: { killTarget != nil || !multiKillTargets.isEmpty },
            set: { if !$0 {
                killTarget = nil
                multiKillTargets = []
            }}
        )
    }

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
                selectedFilter: filterBinding
            )

            StyledTable(
                processes: filteredProcesses,
                selection: $selection,
                sortOrder: $sortOrder
            )
            .accentColor(.primary)
            .contextMenu(forSelectionType: LucidProcess.ID.self) { selectedIDs in
                contextMenuContent(for: selectedIDs)
            }
            .confirmationDialog(
                killDialogTitle,
                isPresented: killConfirmationBinding,
                presenting: killTarget ?? multiKillTargets.first
            ) { _ in
                killButton
            } message: { process in
                killDialogMessage(for: process)
            }
        }
        .background(LucidTheme.backgroundBase)
        .toolbar(.hidden)
        .alert("Kill Failed", isPresented: killErrorBinding) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
    }

    @ViewBuilder
    private func contextMenuContent(for selectedIDs: Set<LucidProcess.ID>) -> some View {
        if selectedIDs.isEmpty {
            EmptyView()
        } else if selectedIDs.count == 1,
                  let id = selectedIDs.first,
                  let process = filteredProcesses.first(where: { $0.id == id }) {
            singleSelectionMenu(for: process)
        } else if selectedIDs.count > 1 {
            multiSelectionMenu(count: selectedIDs.count, ids: selectedIDs)
        }
    }

    private func singleSelectionMenu(for process: LucidProcess) -> some View {
        Group {
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
        }
    }

    private func multiSelectionMenu(count: Int, ids: Set<LucidProcess.ID>) -> some View {
        Button(role: .destructive) {
            multiKillTargets = filteredProcesses.filter { ids.contains($0.id) }
        } label: {
            Label("Kill \(count) Processes", systemImage: "xmark.circle")
        }
    }

    private var killDialogTitle: String {
        killTarget != nil ? "Kill Process" : "Kill Processes"
    }

    private var killButton: some View {
        Button("Kill", role: .destructive) {
            performKill()
        }
    }

    private func performKill() {
        let processesToKill: [LucidProcess]
        if let single = killTarget {
            processesToKill = [single]
            killTarget = nil
        } else {
            processesToKill = multiKillTargets
            multiKillTargets = []
        }

        if case .failure(let error) = monitor.killProcesses(processesToKill) {
            killError = error.localizedDescription
        } else {
            selection.removeAll()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                monitor.refresh()
            }
        }
    }

    private func killDialogMessage(for process: LucidProcess) -> some View {
        if let single = killTarget {
            Text("Are you sure you want to kill \(single.name) (PID: \(single.pid))?")
        } else {
            Text("Are you sure you want to kill \(multiKillTargets.count) processes?")
        }
    }
}
