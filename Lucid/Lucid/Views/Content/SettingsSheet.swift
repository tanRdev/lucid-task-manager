import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("pauseWhenInactive") private var pauseWhenInactive = false
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)

                Toggle("Pause when inactive", isOn: $pauseWhenInactive)
            } header: {
                Text("Appearance & Energy")
            } footer: {
                Text(pauseWhenInactive
                    ? "Monitoring stops when Lucid loses focus."
                    : "Monitoring continues at a lower cadence while inactive.")
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)

                Button("View Releases") {
                    openURL("https://github.com/tanRdev/lucid-task-manager/releases")
                }

                Button("Visit Repository") {
                    openURL("https://github.com/tanRdev/lucid-task-manager")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func openURL(_ string: String) {
        if let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
    }
}
