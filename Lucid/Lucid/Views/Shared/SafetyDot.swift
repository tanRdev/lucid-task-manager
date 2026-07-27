import SwiftUI

struct OriginDot: View {
    let origin: ProcessOrigin

    var body: some View {
        Circle()
            .fill(origin.color)
            .frame(width: 6, height: 6)
            .accessibilityLabel("\(origin.label) process")
    }
}

typealias SafetyDot = OriginDot
