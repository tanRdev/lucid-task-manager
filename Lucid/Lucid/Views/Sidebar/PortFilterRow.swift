import SwiftUI

struct PortFilterRow: View {
    let port: UInt16
    let isActive: Bool
    let onSelect: () -> Void
    let onKill: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack(spacing: 8) {
                    Image(systemName: "network")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(":\(port)")
                        .font(.body.monospacedDigit())

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("Filter by Port \(port)", action: onSelect)
                Button("Kill Listening Processes…", role: .destructive, action: onKill)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel("Actions for port \(port)")
        }
        .padding(.vertical, 2)
        .listRowBackground(isActive ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
    }
}
