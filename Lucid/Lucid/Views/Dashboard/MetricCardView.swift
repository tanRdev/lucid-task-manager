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

#Preview {
    MetricCardView(
        label: "CPU",
        value: "45.2%",
        icon: "cpu",
        color: Color(red: 1.0, green: 0.35, blue: 0.0),
        history: [30, 35, 32, 40, 45, 42, 38, 41, 44, 45, 43, 42]
    )
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
}
