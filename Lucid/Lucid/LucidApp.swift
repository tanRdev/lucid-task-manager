import SwiftUI

@main
struct LucidApp: App {
    @State private var monitor = ProcessMonitor()
    @State private var lifecycleObservers: [Any] = []

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitor)
                .environment(monitor.processStore)
                .environment(monitor.statsStore)
                .environment(monitor.filterState)
                .frame(minWidth: 1100, minHeight: 750)
                .onAppear {
                    monitor.start()
                    setupLifecycleObservers()
                }
        }
        .windowStyle(.hiddenTitleBar)
    }

    private func setupLifecycleObservers() {
        guard lifecycleObservers.isEmpty else { return }
        lifecycleObservers = [
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil, queue: .main
            ) { _ in
                Task { @MainActor in monitor.stop() }
            },
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil, queue: .main
            ) { _ in
                Task { @MainActor in monitor.start() }
            }
        ]
    }
}