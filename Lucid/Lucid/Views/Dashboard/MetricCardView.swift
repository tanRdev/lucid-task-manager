import SwiftUI

struct MetricCardView: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let history: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(.caption2, design: .default))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
            }
        }
        .padding(8)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .cornerRadius(6)
    }
}
