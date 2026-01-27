import SwiftUI

struct MetricCardView: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let history: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            Text(value)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)

            if !history.isEmpty {
                BarSparkline(data: history, color: color)
                    .frame(height: 32)
            } else {
                Spacer()
                    .frame(height: 32)
            }
        }
        .padding(12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .cornerRadius(8)
    }
}
