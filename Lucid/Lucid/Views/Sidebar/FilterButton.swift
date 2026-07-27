import SwiftUI

struct FilterButton: View {
    let label: String
    let icon: String
    let count: Int
    var isActive = false
    var action: () -> Void = {}

    var body: some View {
        // Kept for Dashboard compatibility; sidebar uses native List rows.
        Button(action: action) {
            Label {
                HStack {
                    Text(label)
                    Spacer()
                    Text(verbatim: LucidFormat.count(count))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: icon)
            }
        }
        .buttonStyle(.plain)
    }
}
