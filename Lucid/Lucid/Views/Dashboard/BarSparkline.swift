import SwiftUI
import Charts

struct BarSparkline: View {
    let data: [Double]
    let color: Color

    private func barOpacity(for index: Int) -> Double {
        0.5 + (Double(index) / Double(data.count)) * 0.5
    }

    var body: some View {
        if data.isEmpty {
            HStack {
                Text("No data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            let enumData = Array(data.enumerated())
            Chart {
                ForEach(enumData, id: \.offset) { index, value in
                    let opacity = barOpacity(for: index)
                    BarMark(
                        x: .value("Value", value),
                        y: .value("Index", index)
                    )
                    .foregroundStyle(color.opacity(opacity))
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
        }
    }
}
