import SwiftUI

struct SafetyTag: View {
    let safety: Safety

    var body: some View {
        Text(safety.label)
            .font(.system(size: LucidTheme.fontSizeXS, weight: .medium, design: .default))
            .foregroundStyle(safety.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(safety.color.opacity(0.15))
            .clipShape(Capsule())
    }
}
