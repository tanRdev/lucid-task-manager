import SwiftUI

struct PortFilterRow: View {
    let port: UInt16
    let processCount: Int
    let isActive: Bool
    let onSelect: () -> Void
    let onKill: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .frame(width: 20)
                    .foregroundStyle(.cyan)
                Text(":\(port)")
                    .font(.system(.body, design: .monospaced))
                Spacer()

                Button(action: onKill) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.red.opacity(isHovering ? 0.7 : 0.0001))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Kill all processes on port \(port)")

                Text("\(processCount)")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LucidTheme.badgeBackground)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                isActive ?
                LucidTheme.borderPrimary :
                Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
