import SwiftUI

@main
struct LucidApp: App {
    @State private var monitor = ProcessMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize(CGSize(width: 1100, height: 750)))
        .onAppear {
            monitor.start()
        }
        .onDisappear {
            monitor.stop()
        }
    }
}
