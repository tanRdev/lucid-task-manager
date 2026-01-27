import SwiftUI

struct FilterButton: View {
    let label: String
    let icon: String
    let count: Int
    var isActive = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(.body, design: .default))
                    Text("\(count) processes")
                        .font(.system(.caption, design: .default))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(count)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LucidTheme.badgeBackground)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                isActive ?
                LucidTheme.borderPrimary :
                Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
