import SwiftUI

struct HeaderBar: View {
    @Environment(FilterState.self) var filterState
    @State private var showSettings = false

    let processCount: Int

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { filterState.searchText },
            set: { filterState.searchText = $0 }
        )
    }

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

            SearchField(text: searchTextBinding)
        }
        .padding(16)
        .background(LucidTheme.backgroundSecondary)
        .border(LucidTheme.backgroundTertiary, width: 1)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }
}

// MARK: - Search Field Component

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search processes...", text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(LucidTheme.backgroundTertiary)
        .cornerRadius(8)
        .frame(maxWidth: 250)
    }
}