import SwiftUI

struct StyledTable: View {
    let processes: [LucidProcess]
    @Binding var selection: Set<ProcessIdentity>

    var body: some View {
        Table(processes, selection: $selection) {
            TableColumn("Name") { process in
                Text(process.name)
                    .font(.body)
                    .lineLimit(1)
                    .help(process.description)
            }
            .width(min: 120, ideal: 180)

            TableColumn("Origin") { process in
                OriginTag(origin: process.origin)
            }
            .width(min: 92, ideal: 108)

            TableColumn("Description") { process in
                Text(process.description)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(process.description)
            }
            .width(min: 140, ideal: 240)

            TableColumn("CPU") { process in
                Text(verbatim: process.cpuFormatted)
                    .font(.body.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundStyle(process.cpuUsage >= 80 ? LucidTheme.statusCritical : .primary)
            }
            .width(min: 64, ideal: 72)

            TableColumn("Memory") { process in
                Text(verbatim: process.memoryFormatted)
                    .font(.body.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 92)

            TableColumn("PID") { process in
                Text(verbatim: LucidFormat.pid(process.pid))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 56, ideal: 64)

            TableColumn("Ports") { process in
                Text(verbatim: process.portsFormatted)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(process.ports.isEmpty ? .tertiary : .secondary)
                    .lineLimit(1)
                    .help(process.portsFormatted)
            }
            .width(min: 64, ideal: 88)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
    }
}
