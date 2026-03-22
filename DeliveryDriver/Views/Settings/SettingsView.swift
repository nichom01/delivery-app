import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var locationFrequencyText = ""
    @State private var transmissionFrequencyText = ""

    var body: some View {
        List {
            locationSection
            transmissionSection
            endpointsSection
            versionSection
        }
        .scrollContentBackground(.hidden)
        .background(DS.Colors.background)
        .listStyle(.insetGrouped)
        .onAppear {
            locationFrequencyText = "\(settings.locationFrequency)"
            transmissionFrequencyText = "\(settings.transmissionFrequency)"
        }
    }

    // MARK: - Sections

    private var locationSection: some View {
        Section {
            settingsRow(
                icon: "location.fill",
                iconColor: DS.Colors.accent,
                title: "Location Tracking"
            ) {
                Toggle("", isOn: $settings.locationEnabled)
                    .tint(DS.Colors.accent)
                    .onChange(of: settings.locationEnabled) { enabled in
                        enabled ? LocationService.shared.start() : LocationService.shared.stop()
                    }
            }

            settingsRow(
                icon: "timer",
                iconColor: DS.Colors.accent,
                title: "Capture Frequency (s)"
            ) {
                TextField("30", text: $locationFrequencyText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(DS.Colors.textSecondary)
                    .onChange(of: locationFrequencyText) { val in
                        if let n = Int(val), n > 0 {
                            settings.locationFrequency = n
                            LocationService.shared.restartIfEnabled()
                        }
                    }
            }
        } header: {
            sectionHeader("Location")
        }
        .listRowBackground(DS.Colors.card)
    }

    private var transmissionSection: some View {
        Section {
            settingsRow(
                icon: "arrow.up.arrow.down.circle.fill",
                iconColor: .blue,
                title: "Data Sync"
            ) {
                Toggle("", isOn: $settings.transmissionEnabled)
                    .tint(DS.Colors.accent)
                    .onChange(of: settings.transmissionEnabled) { enabled in
                        enabled ? SyncService.shared.start() : SyncService.shared.stop()
                    }
            }

            settingsRow(
                icon: "clock.fill",
                iconColor: .blue,
                title: "Sync Frequency (s)"
            ) {
                TextField("60", text: $transmissionFrequencyText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(DS.Colors.textSecondary)
                    .onChange(of: transmissionFrequencyText) { val in
                        if let n = Int(val), n > 0 {
                            settings.transmissionFrequency = n
                            SyncService.shared.restartIfEnabled()
                        }
                    }
            }
        } header: {
            sectionHeader("Sync")
        }
        .listRowBackground(DS.Colors.card)
    }

    private var endpointsSection: some View {
        Section {
            endpointRow(icon: "lock.shield", label: "Login",      binding: $settings.loginEndpoint)
            endpointRow(icon: "barcode",      label: "Load",       binding: $settings.loadEndpoint)
            endpointRow(icon: "doc.text",     label: "Manifest",   binding: $settings.manifestEndpoint)
            endpointRow(icon: "paperplane",   label: "Submission", binding: $settings.submissionEndpoint)
        } header: {
            sectionHeader("API Endpoints")
        }
        .listRowBackground(DS.Colors.card)
    }

    private var versionSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .listRowBackground(DS.Colors.card)
    }

    // MARK: - Helpers

    private func settingsRow<Accessory: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(title)
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textPrimary)

            Spacer()
            accessory()
        }
        .padding(.vertical, 2)
    }

    private func endpointRow(icon: String, label: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label(label, systemImage: icon)
                .font(DS.Typography.caption())
                .foregroundColor(DS.Colors.textSecondary)

            TextField("https://", text: binding)
                .font(DS.Typography.body())
                .foregroundColor(DS.Colors.textPrimary)
                .tint(DS.Colors.accent)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(.vertical, DS.Spacing.xs)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DS.Typography.micro())
            .foregroundColor(DS.Colors.textSecondary)
    }
}
