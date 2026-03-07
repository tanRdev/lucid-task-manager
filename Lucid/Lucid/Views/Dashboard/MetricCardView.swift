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
                    .frame(width: 14, height: 14)

                Text(label)
                    .font(.system(.caption2, design: .default))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
            }

            // Mini sparkline when history available
            if !history.isEmpty {
                MiniSparkline(data: history, color: color)
                    .frame(height: 12)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .background(LucidTheme.backgroundTertiary)
        .cornerRadius(6)
        .help("\(label): \(value)")
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue

            Path { path in
                guard data.count > 1 else { return }

                let stepX = width / CGFloat(data.count - 1)

                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = range > 0 ? height - ((CGFloat(value - minValue) / CGFloat(range)) * height) : height / 2

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color.opacity(0.6), lineWidth: 1.5)
        }
    }
}