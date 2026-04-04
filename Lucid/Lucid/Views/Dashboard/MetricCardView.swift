import SwiftUI

struct MetricCardView: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let history: [Double]

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 12)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .help("\(label): \(value)")
    }
}
