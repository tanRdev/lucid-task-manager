import SwiftUI
import Charts

struct BarSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        if data.isEmpty {
            HStack {
                Text("No data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    BarMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(color.opacity(0.5 + (Double(index) / Double(data.count)) * 0.5))
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .chartPlotAreaBackground(Color.clear)
        }
    }
}

#Preview {
    BarSparkline(
        data: [30, 35, 32, 40, 45, 42, 38, 41, 44, 45, 43, 42],
        color: Color(red: 1.0, green: 0.35, blue: 0.0)
    )
    .frame(height: 40)
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.1))
}
