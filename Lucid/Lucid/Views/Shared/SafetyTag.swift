import SwiftUI

struct OriginTag: View {
    let origin: ProcessOrigin

    var body: some View {
        Text(origin.label)
            .font(.caption.weight(.medium))
            .foregroundStyle(origin.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(origin.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel("Origin \(origin.label)")
    }
}

/// Legacy name kept for older call sites.
typealias SafetyTag = OriginTag
