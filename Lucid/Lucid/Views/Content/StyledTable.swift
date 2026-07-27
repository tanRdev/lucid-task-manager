import SwiftUI

struct StyledTable: View {
    let processes: [LucidProcess]
    @Binding var selection: Set<ProcessIdentity>
    @Binding var sortKey: ProcessSortKey
    @Binding var sortAscending: Bool

    var body: some View {
        Table(processes, selection: $selection) {
            TableColumn("Name") { process in
                Text(process.name)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .help(process.description)
            }
            .width(min: 120, ideal: 180)

            TableColumn("Origin") { process in
                OriginTag(origin: process.origin)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Description") { process in
                Text(process.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(process.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(min: 140, ideal: 220)

            TableColumn("CPU") { process in
                Text(process.cpuFormatted)
                    .font(.body.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 60, ideal: 70)

            TableColumn("Memory") { process in
                Text(process.memoryFormatted)
                    .font(.body.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 90)

            TableColumn("PID") { process in
                Text(String(process.pid))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 50, ideal: 60)

            TableColumn("Ports") { process in
                Text(process.portsFormatted)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .help(process.portsFormatted)
            }
            .width(min: 60, ideal: 80)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .safeAreaInset(edge: .top, spacing: 0) {
            sortBar
        }
    }

    private var sortBar: some View {
        HStack(spacing: 8) {
            Text("Sort")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Sort", selection: $sortKey) {
                ForEach(ProcessSortKey.allCases) { key in
                    Text(key.label).tag(key)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: 140)

            Button {
                sortAscending.toggle()
            } label: {
                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
            }
            .buttonStyle(.borderless)
            .help(sortAscending ? "Ascending" : "Descending")

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
