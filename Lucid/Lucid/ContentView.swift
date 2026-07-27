import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(ProcessMonitor.self) var monitor
    @AppStorage("appTheme") private var appTheme: String = "system"
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var inspectorPresented = false

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            DetailView(inspectorPresented: $inspectorPresented)
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(colorScheme)
        .onAppear {
            updateAssistiveTechFlag()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didActivateApplicationNotification)) { _ in
            updateAssistiveTechFlag()
        }
    }

    private func updateAssistiveTechFlag() {
        // Pause aggressive refresh while VoiceOver (or similar) is running.
        let running = NSWorkspace.shared.runningApplications.contains {
            let id = $0.bundleIdentifier ?? ""
            return id == "com.apple.VoiceOver" || id.contains("VoiceOver")
        }
        monitor.setAssistiveTechnologyActive(running)
    }
}

enum ProcessSortKey: String, CaseIterable, Identifiable, Sendable {
    case name
    case origin
    case description
    case cpu
    case memory
    case pid
    case ports

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name: return "Name"
        case .origin: return "Origin"
        case .description: return "Description"
        case .cpu: return "CPU"
        case .memory: return "Memory"
        case .pid: return "PID"
        case .ports: return "Ports"
        }
    }
}

struct DetailView: View {
    @Environment(ProcessMonitor.self) var monitor
    @Binding var inspectorPresented: Bool
    @State private var searchText = ""
    @State private var sortKey: ProcessSortKey = .cpu
    @State private var sortAscending = false
    @State private var killTarget: LucidProcess?
    @State private var multiKillTargets: [LucidProcess] = []
    @State private var selection = Set<ProcessIdentity>()
    @State private var killError: String?
    @State private var inspectedProcess: LucidProcess?
    /// Cached filter/sort output — avoids re-sorting hundreds of rows on every body pass.
    @State private var displayedProcesses: [LucidProcess] = []

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

    private var selectedProcess: LucidProcess? {
        if let inspected = inspectedProcess,
           let match = displayedProcesses.first(where: { $0.identity == inspected.identity }) {
            return match
        }
        if let id = selection.first {
            return displayedProcesses.first(where: { $0.identity == id })
        }
        return nil
    }

    var body: some View {
        Group {
            if monitor.isLoading && monitor.processes.isEmpty {
                ContentUnavailableView("Loading processes…", systemImage: "arrow.triangle.2.circlepath")
            } else if displayedProcesses.isEmpty {
                emptyState
            } else {
                StyledTable(
                    processes: displayedProcesses,
                    selection: $selection
                )
                .contextMenu(forSelectionType: ProcessIdentity.self) { selectedIDs in
                    contextMenuContent(for: selectedIDs)
                } primaryAction: { selectedIDs in
                    if let id = selectedIDs.first,
                       let process = displayedProcesses.first(where: { $0.identity == id }) {
                        inspectedProcess = process
                        inspectorPresented = true
                    }
                }
            }
        }
        .background(LucidTheme.backgroundBase)
        .navigationTitle("Processes")
        .navigationSubtitle(subtitle)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search processes")
        .onAppear { rebuildDisplayedProcesses() }
        .onChange(of: monitor.lastUpdated) { _, _ in rebuildDisplayedProcesses() }
        .onChange(of: monitor.selectedFilter) { _, _ in rebuildDisplayedProcesses() }
        .onChange(of: searchText) { _, _ in rebuildDisplayedProcesses() }
        .onChange(of: sortKey) { _, _ in rebuildDisplayedProcesses() }
        .onChange(of: sortAscending) { _, _ in rebuildDisplayedProcesses() }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Sort", selection: $sortKey) {
                    ForEach(ProcessSortKey.allCases) { key in
                        Text(key.label).tag(key)
                    }
                }
                .pickerStyle(.menu)
                .help("Sort processes")

                Button {
                    sortAscending.toggle()
                } label: {
                    Label(
                        sortAscending ? "Ascending" : "Descending",
                        systemImage: sortAscending ? "arrow.up" : "arrow.down"
                    )
                }
                .help(sortAscending ? "Sort ascending" : "Sort descending")

                Button {
                    if monitor.isRunning {
                        monitor.stop()
                    } else {
                        monitor.start()
                    }
                } label: {
                    Label(
                        monitor.isRunning ? "Pause" : "Resume",
                        systemImage: monitor.isRunning ? "pause.fill" : "play.fill"
                    )
                }
                .help(monitor.isRunning ? "Pause monitoring" : "Resume monitoring")

                Button {
                    monitor.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh now")

                Button {
                    inspectorPresented.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Toggle process inspector")
            }
        }
        .inspector(isPresented: $inspectorPresented) {
            ProcessInspectorView(
                process: selectedProcess,
                onKill: { process in
                    if process.origin.allowsTermination {
                        killTarget = process
                    }
                }
            )
            .inspectorColumnWidth(min: 260, ideal: 300, max: 400)
        }
        .onChange(of: selection) { _, newValue in
            if let id = newValue.first,
               let process = displayedProcesses.first(where: { $0.identity == id }) {
                inspectedProcess = process
            }
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
        .alert("Kill Failed", isPresented: killErrorBinding) {
            Button("OK") { killError = nil }
        } message: {
            Text(killError ?? "")
        }
        .overlay(alignment: .bottom) {
            if let error = monitor.lastError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(LucidTheme.statusWarning)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Button {
                        monitor.lastError = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(LucidTheme.borderSubtle, lineWidth: 0.5)
                )
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var subtitle: String {
        var parts = ["\(LucidFormat.count(displayedProcesses.count)) shown"]
        if let updated = monitor.lastUpdated {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            parts.append("Updated \(formatter.localizedString(for: updated, relativeTo: Date()))")
        }
        return parts.joined(separator: " · ")
    }

    private func rebuildDisplayedProcesses() {
        var result = monitor.processes

        switch monitor.selectedFilter {
        case .all:
            break
        case .system:
            result = result.filter { $0.origin == .system }
        case .user:
            result = result.filter { $0.origin == .user }
        case .unknown:
            result = result.filter { $0.origin == .unknown }
        case .port(let port):
            result = result.filter { $0.ports.contains(port) }
        }

        if !searchText.isEmpty {
            let query = searchText
            result = result.filter { process in
                process.name.localizedCaseInsensitiveContains(query) ||
                process.description.localizedCaseInsensitiveContains(query) ||
                LucidFormat.pid(process.pid).contains(query)
            }
        }

        result.sort { lhs, rhs in
            let ordered: Bool
            switch sortKey {
            case .name:
                ordered = lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .origin:
                ordered = lhs.origin.rawValue < rhs.origin.rawValue
            case .description:
                ordered = lhs.description.localizedCaseInsensitiveCompare(rhs.description) == .orderedAscending
            case .cpu:
                ordered = lhs.cpuUsage < rhs.cpuUsage
            case .memory:
                ordered = lhs.memoryBytes < rhs.memoryBytes
            case .pid:
                ordered = lhs.pid < rhs.pid
            case .ports:
                ordered = (lhs.ports.first ?? 0) < (rhs.ports.first ?? 0)
            }
            return sortAscending ? ordered : !ordered
        }

        displayedProcesses = result
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty || monitor.selectedFilter != .all {
            ContentUnavailableView {
                Label("No Results", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text("No processes match the current search or filter.")
            } actions: {
                Button("Clear Filters") {
                    searchText = ""
                    monitor.selectedFilter = .all
                }
            }
        } else {
            ContentUnavailableView("No Processes", systemImage: "cpu", description: Text("Waiting for process data."))
        }
    }

    @ViewBuilder
    private func contextMenuContent(for selectedIDs: Set<ProcessIdentity>) -> some View {
        if selectedIDs.isEmpty {
            EmptyView()
        } else if selectedIDs.count == 1,
                  let id = selectedIDs.first,
                  let process = displayedProcesses.first(where: { $0.identity == id }) {
            singleSelectionMenu(for: process)
        } else if selectedIDs.count > 1 {
            multiSelectionMenu(ids: selectedIDs)
        }
    }

    private func singleSelectionMenu(for process: LucidProcess) -> some View {
        Group {
            if process.origin.allowsTermination {
                Button(role: .destructive) {
                    killTarget = process
                } label: {
                    Label("Kill Process", systemImage: "xmark.circle")
                }
            } else {
                Text("Protected system process")
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

            Button {
                inspectedProcess = process
                inspectorPresented = true
            } label: {
                Label("Get Info", systemImage: "info.circle")
            }
        }
    }

    private func multiSelectionMenu(ids: Set<ProcessIdentity>) -> some View {
        let targets = displayedProcesses.filter { ids.contains($0.identity) && $0.origin.allowsTermination }
        return Group {
            if targets.isEmpty {
                Text("No killable processes in selection")
            } else {
                Button(role: .destructive) {
                    multiKillTargets = targets
                } label: {
                    Label("Kill \(LucidFormat.count(targets.count)) Processes", systemImage: "xmark.circle")
                }
            }
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
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                monitor.refresh()
            }
        }
    }

    private func killDialogMessage(for process: LucidProcess) -> some View {
        if killTarget != nil {
            Text("Terminate \(process.name) (PID \(LucidFormat.pid(process.pid)))? This cannot be undone.")
        } else {
            Text("Terminate \(LucidFormat.count(multiKillTargets.count)) processes? Protected system processes are excluded.")
        }
    }
}

struct ProcessInspectorView: View {
    let process: LucidProcess?
    let onKill: (LucidProcess) -> Void

    var body: some View {
        Group {
            if let process {
                Form {
                    Section("Process") {
                        LabeledContent("Name") {
                            Text(process.name)
                                .textSelection(.enabled)
                        }
                        LabeledContent("PID") {
                            Text(verbatim: LucidFormat.pid(process.pid))
                                .font(.body.monospacedDigit())
                                .textSelection(.enabled)
                        }
                        LabeledContent("Origin") {
                            OriginTag(origin: process.origin)
                        }
                        LabeledContent("User ID") {
                            Text(verbatim: LucidFormat.userID(process.userID))
                                .font(.body.monospacedDigit())
                        }
                        LabeledContent("CPU") {
                            Text(verbatim: process.cpuFormatted)
                                .font(.body.monospacedDigit())
                        }
                        LabeledContent("Memory (RSS)") {
                            Text(verbatim: process.memoryFormatted)
                                .font(.body.monospacedDigit())
                        }
                        LabeledContent("Ports") {
                            Text(verbatim: process.portsFormatted)
                                .font(.body.monospacedDigit())
                                .textSelection(.enabled)
                        }
                    }

                    Section("Description") {
                        Text(process.description)
                            .textSelection(.enabled)
                    }

                    Section("Executable") {
                        Text(process.exePath)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        Button("Copy Path") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(process.exePath, forType: .string)
                        }
                        Button("Show in Finder") {
                            NSWorkspace.shared.selectFile(process.exePath, inFileViewerRootedAtPath: "")
                        }
                    }

                    Section("Actions") {
                        if process.origin.allowsTermination {
                            Button("Kill Process", role: .destructive) {
                                onKill(process)
                            }
                        } else {
                            Text("Protected — system-origin processes cannot be terminated from Lucid.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "sidebar.trailing",
                    description: Text("Select a process to inspect details.")
                )
            }
        }
        .navigationTitle("Inspector")
    }
}
