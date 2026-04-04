import SwiftUI
import AppKit

struct StyledTable: View {
    let processes: [LucidProcess]
    @Binding var selection: Set<LucidProcess.ID>
    @Binding var sortOrder: [KeyPathComparator<LucidProcess>]

    var body: some View {
        Table(processes, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { process in
                Text(process.name)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TableColumn("Tag") { process in
                HStack(spacing: 4) {
                    Image(systemName: process.safety.systemImage)
                        .font(.system(size: 10))
                        .foregroundStyle(process.safety.color)
                    Text(process.safety.label)
                        .font(.system(size: LucidTheme.fontSizeXS, weight: .medium))
                        .foregroundStyle(process.safety.color)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(process.safety.color.opacity(0.15))
                .clipShape(Capsule())
            }
            .width(min: 80, ideal: 100)

            TableColumn("Description", value: \.description) { process in
                Text(process.description)
                    .font(.system(.body, design: .default))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TableColumn("CPU", value: \.cpuUsage) { process in
                Text(process.cpuFormatted)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TableColumn("Memory", value: \.memoryBytes) { process in
                Text(process.memoryFormatted)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TableColumn("Path", value: \.exePath) { process in
                Text(process.exePath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .tableStyle(.automatic)
        .alternatingRowBackgrounds(.disabled)
        .background(LucidTheme.backgroundBase)
    }
}
