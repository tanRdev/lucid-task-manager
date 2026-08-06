import SwiftUI

struct OriginTag: View {
    let origin: ProcessOrigin

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: origin.systemImage)
                .font(.system(size: 9, weight: .semibold))
            Text(origin.label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(origin.color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(origin.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Origin \(origin.label)")
    }
}
