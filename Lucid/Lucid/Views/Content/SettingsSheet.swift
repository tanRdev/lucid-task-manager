import SwiftUI
import AppKit

struct SettingsSheet: View {
    @AppStorage("appTheme") private var appTheme: String = "system"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Settings Content
            VStack(alignment: .leading, spacing: 24) {
                // Appearance
                VStack(alignment: .leading, spacing: 10) {
                    Label("Appearance", systemImage: "paintbrush")
                        .font(.headline)

                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // Updates
                VStack(alignment: .leading, spacing: 10) {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)

                    Button(action: checkForUpdates) {
                        HStack {
                            Text("Check for Updates")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // About
                VStack(alignment: .leading, spacing: 10) {
                    Label("About", systemImage: "info.circle")
                        .font(.headline)

                    Button(action: openRepository) {
                        HStack {
                            Text("Visit Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)

            Spacer()
        }
        .frame(width: 380, height: 400)
    }

    private func checkForUpdates() {
        // Placeholder for update check functionality
    }

    private func openRepository() {
        if let url = URL(string: "https://github.com/anthropics/lucid") {
            NSWorkspace.shared.open(url)
        }
    }
}
