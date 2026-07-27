import SwiftUI

struct PortFilterRow: View {
    let port: UInt16
    let onKill: () -> Void

    private var portLabel: String { ":\(LucidFormat.port(port))" }

    var body: some View {
        Label {
            HStack(spacing: 8) {
                Text(verbatim: portLabel)
                    .font(.body.monospacedDigit())

                Spacer(minLength: 4)

                Menu {
                    Button("Kill Listening Processes…", role: .destructive, action: onKill)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .tint(.secondary)
                .fixedSize()
                .help("Port actions")
                .accessibilityLabel("Actions for port \(LucidFormat.port(port))")
            }
        } icon: {
            Image(systemName: "network")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
    }
}
