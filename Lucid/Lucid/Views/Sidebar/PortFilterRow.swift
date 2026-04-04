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
                Text(":\(port)")
                    .font(.system(.body, design: .monospaced))

                Spacer()

                if isHovering {
                    Button(action: onKill) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(LucidTheme.safetyUnknown)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Kill all processes on port \(port)")
                }

                Text("\(processCount)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
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
