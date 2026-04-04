import SwiftUI

struct PortFilterRow: View {
    let port: UInt16
    let isActive: Bool
    let onSelect: () -> Void
    let onKill: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Text(":\(port)")
                    .font(.system(.body, design: .monospaced))

                Spacer()

                if isHovering {
                    Button(action: onKill) {
                        Text("KILL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(LucidTheme.safetyUnknown)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LucidTheme.safetyUnknown.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Kill all processes on port \(port)")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(isActive ? Color(NSColor.selectedControlColor) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
