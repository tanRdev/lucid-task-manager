import SwiftUI

struct PulsingStatusDot: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(LucidTheme.statusSuccess)
            .frame(width: 6, height: 6)
            .opacity(isPulsing ? 1.0 : 0.5)
            .animation(
                monitor.isRunning
                    ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onChange(of: monitor.isRunning) { _, running in
                isPulsing = running
            }
            .onAppear { isPulsing = monitor.isRunning }
    }
}
