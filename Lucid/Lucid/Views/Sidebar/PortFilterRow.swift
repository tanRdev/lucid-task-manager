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

                if isHovering {
                    Button(action: onKill) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.red.opacity(0.7))
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .help("Kill all processes on port \(port)")
                }

                Text("\(processCount)")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isActive ?
                Color(red: 0.15, green: 0.15, blue: 0.2) :
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
