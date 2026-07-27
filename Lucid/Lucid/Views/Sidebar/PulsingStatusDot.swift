import SwiftUI

/// In-place opacity pulse only — never scales or moves layout (avoids window/safe-area bounce).
struct PulsingStatusDot: View {
    @Environment(ProcessMonitor.self) var monitor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if shouldPulse {
                TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: false)) { context in
                    Circle()
                        .fill(LucidTheme.statusSuccess)
                        .opacity(pulseOpacity(at: context.date))
                }
            } else {
                Circle()
                    .fill(monitor.isRunning ? LucidTheme.statusSuccess : Color.secondary)
            }
        }
        .frame(width: 6, height: 6)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var shouldPulse: Bool {
        monitor.isRunning && !reduceMotion
    }

    private func pulseOpacity(at date: Date) -> Double {
        // Smooth 0.4…1.0 opacity cycle (~1.6s). Position stays fixed.
        let period = 1.6
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        return 0.4 + 0.6 * (0.5 + 0.5 * sin(phase * 2 * .pi))
    }
}
