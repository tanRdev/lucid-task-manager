import SwiftUI

struct HoverKillButton: View {
    let process: LucidProcess
    var isRowHovered: Bool = false
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.red.opacity(isHovering ? 1.0 : 0.7))
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .opacity(isRowHovered || isHovering ? 1.0 : 0.0)
        .onHover { hovering in
            isHovering = hovering
        }
        .help("Kill process \(process.name) (PID: \(process.pid))")
    }
}
