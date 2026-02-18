import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var localMode: Bool = Config.shared.localMode
    @State private var serverURL: String = Config.shared.serverURL
    @State private var authToken: String = Config.shared.authToken
    @State private var resumeTimeout: TimeInterval = Config.shared.resumeTimeoutSeconds
    @AppStorage("den.colorScheme") private var colorSchemeRaw: String = "system"

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                modeSection
                if !localMode {
                    serverSection
                    authSection
                }
                resumeSection
                appearanceSection
                infoSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(DenTheme.accent)
                }
            }
        }
    }

    @ViewBuilder
    private var modeSection: some View {
        Section {
            Toggle("Local Mode", isOn: $localMode)
                .tint(DenTheme.accent)
        } header: {
            Text("Storage")
        } footer: {
            Text(localMode
                 ? "Notes are stored on this device only."
                 : "Notes sync with your Den server.")
        }
    }

    @ViewBuilder
    private var serverSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Server URL")
                    .font(DenTheme.captionFont)
                    .foregroundStyle(.secondary)
                TextField("https://your-server.com", text: $serverURL)
                    .font(DenTheme.bodyFont)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .textContentType(.URL)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Server")
        } footer: {
            Text("The URL of your Den sync server.")
        }
    }

    @ViewBuilder
    private var authSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Auth Token")
                    .font(DenTheme.captionFont)
                    .foregroundStyle(.secondary)
                SecureField("Paste your token here", text: $authToken)
                    .font(DenTheme.bodyFont)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .textContentType(.password)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Authentication")
        } footer: {
            Text("Your personal auth token for the sync server.")
        }
    }

    @ViewBuilder
    private var resumeSection: some View {
        Section {
            Picker("Resume Timeout", selection: $resumeTimeout) {
                Text("1 minute").tag(TimeInterval(60))
                Text("2 minutes").tag(TimeInterval(120))
                Text("5 minutes").tag(TimeInterval(300))
                Text("10 minutes").tag(TimeInterval(600))
                Text("Never").tag(TimeInterval(0))
            }
            .pickerStyle(.menu)
            .foregroundStyle(.primary)
        } header: {
            Text("Session")
        } footer: {
            Text("How long before the app re-syncs when returning from background.")
        }
    }

    @ViewBuilder
    private var appearanceSection: some View {
        Section {
            Picker("Color Scheme", selection: $colorSchemeRaw) {
                Text("Follow System").tag("system")
                Text("Always Dark").tag("dark")
                Text("Always Light").tag("light")
            }
            .pickerStyle(.menu)
        } header: {
            Text("Appearance")
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
                    .font(DenTheme.captionFont)
            }

            HStack {
                Text("Built with")
                    .foregroundStyle(.primary)
                Spacer()
                Text("SwiftUI + TextKit 2")
                    .foregroundStyle(.secondary)
                    .font(DenTheme.captionFont)
            }
        } header: {
            Text("About Den")
        }
    }

    private func saveSettings() {
        Config.shared.localMode = localMode
        Config.shared.serverURL = serverURL
        Config.shared.authToken = authToken
        Config.shared.resumeTimeoutSeconds = resumeTimeout
    }
}
