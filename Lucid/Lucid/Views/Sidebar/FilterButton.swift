import SwiftUI

struct FilterButton: View {
    let label: String
    let icon: String
    let count: Int
    var isActive = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isActive ? .primary : .secondary)
                    .frame(width: 18)

                Text(label)
                    .font(.system(.body, design: .default))

                Spacer()

                Text("\(count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(isActive ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
