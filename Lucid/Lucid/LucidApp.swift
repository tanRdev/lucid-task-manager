import SwiftUI

@main
struct LucidApp: App {
    @State private var monitor = ProcessMonitor()
    @State private var lifecycleObservers: [Any] = []

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitor)
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
                monitor.stop()
            },
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil, queue: .main
            ) { _ in
                monitor.start()
            }
        ]
    }
}
