import SwiftUI

struct PulsingStatusDot: View {
    @Environment(ProcessMonitor.self) var monitor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(monitor.isRunning ? LucidTheme.statusSuccess : Color.secondary)
            .frame(width: 6, height: 6)
            .opacity(shouldAnimate && isPulsing ? 0.45 : 1.0)
            .animation(
                shouldAnimate
                    ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onChange(of: monitor.isRunning) { _, running in
                isPulsing = shouldAnimate && running
            }
            .onAppear {
                isPulsing = shouldAnimate && monitor.isRunning
            }
            .accessibilityHidden(true)
    }

    private var shouldAnimate: Bool {
        monitor.isRunning && !reduceMotion
    }
}
