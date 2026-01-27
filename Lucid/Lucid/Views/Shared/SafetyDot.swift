import SwiftUI

struct SafetyDot: View {
    let safety: Safety

    var body: some View {
        Circle()
            .fill(safety.color)
            .frame(width: 8, height: 8)
            .shadow(color: safety.color.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}
