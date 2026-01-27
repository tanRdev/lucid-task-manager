import SwiftUI

struct PulsingStatusDot: View {
    @Environment(ProcessMonitor.self) var monitor
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 8, height: 8)
            .shadow(color: Color.green.opacity(0.6), radius: isPulsing ? 6 : 2)
            .scaleEffect(isPulsing ? 1.2 : 0.9)
            .opacity(isPulsing ? 1.0 : 0.7)
            .animation(
                monitor.isRunning
                    ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onChange(of: monitor.isRunning) { _, running in
                isPulsing = running
            }
            .onAppear { isPulsing = monitor.isRunning }
    }
}
