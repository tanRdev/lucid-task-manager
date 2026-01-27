import SwiftUI

struct HeaderBar: View {
    let processCount: Int
    @Binding var searchText: String
    @Binding var selectedFilter: FilterCategory
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Processes")
                    .font(.system(.title2, design: .default))
                    .fontWeight(.semibold)

                Text("\(processCount) items")
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search processes...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(LucidTheme.backgroundTertiary)
            .cornerRadius(8)
            .frame(maxWidth: 250)
        }
        .padding(16)
        .background(LucidTheme.backgroundSecondary)
        .border(LucidTheme.backgroundTertiary, width: 1)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }
}
