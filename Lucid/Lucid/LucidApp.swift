import SwiftUI

@main
struct LucidApp: App {
    @State private var monitor = ProcessMonitor()
    @State private var lifecycleObservers: [Any] = []
    @AppStorage("pauseWhenInactive") private var pauseWhenInactive = false

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

        Settings {
            SettingsView()
                .environment(monitor)
        }
    }

    private func setupLifecycleObservers() {
        guard lifecycleObservers.isEmpty else { return }
        lifecycleObservers = [
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil, queue: .main
            ) { _ in
                Task { @MainActor in
                    if pauseWhenInactive {
                        monitor.stop(reason: "inactive")
                    } else {
                        monitor.enterBackgroundCadence()
                    }
                }
            },
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil, queue: .main
            ) { _ in
                Task { @MainActor in
                    monitor.start()
                    monitor.refresh()
                }
            }
        ]
    }
}
