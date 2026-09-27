import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Form {
            Section("Automation") {
                Toggle("Enable automatic scans", isOn: Binding(
                    get: { model.autoScanEnabled },
                    set: { newValue in
                        model.autoScanEnabled = newValue
                        model.startScheduler()
                    }
                ))

                Toggle("Enable automatic safe quick clean", isOn: Binding(
                    get: { model.autoSafeCleanEnabled },
                    set: { newValue in
                        model.autoSafeCleanEnabled = newValue
                        model.persistSettings()
                    }
                ))
            }

            Section("Interval") {
                Picker("Schedule", selection: Binding(
                    get: { model.intervalPreset },
                    set: { model.intervalPreset = $0 }
                )) {
                    ForEach(AutoIntervalPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }

                if model.intervalPreset == .custom {
                    Stepper(
                        "Custom interval: \(model.customIntervalMinutes) minutes",
                        value: Binding(
                            get: { model.customIntervalMinutes },
                            set: {
                                model.customIntervalMinutes = $0
                                model.persistSettings()
                                model.startScheduler()
                            }
                        ),
                        in: 5...1440,
                        step: 5
                    )
                }
            }

            Section("Current state") {
                HStack {
                    Text("Candidates")
                    Spacer()
                    Text("\(model.summary.totalCandidates)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Recoverable")
                    Spacer()
                    Text(model.summary.totalBytes.formattedBytes)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Safe quick clean")
                    Spacer()
                    Text(model.summary.safeQuickCleanBytes.formattedBytes)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
