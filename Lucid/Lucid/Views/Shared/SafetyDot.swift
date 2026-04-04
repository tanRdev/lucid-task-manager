import SwiftUI

struct SafetyDot: View {
    let safety: Safety

    var body: some View {
        Circle()
            .fill(safety.color)
            .frame(width: 6, height: 6)
            .accessibilityLabel("\(safety.label) process")
    }
}
