import SwiftUI

@main
struct LucidApp: App {
    @State private var monitor = ProcessMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitor)
                .frame(minWidth: 1100, minHeight: 750)
                .onAppear {
                    monitor.start()
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
