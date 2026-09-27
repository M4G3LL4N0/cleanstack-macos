import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CleanStack Mac")
                    .font(.headline)

                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                statRow("Candidates", "\(model.summary.totalCandidates)")
                statRow("Recoverable", model.summary.totalBytes.formattedBytes)
                statRow("Safe quick clean", model.summary.safeQuickCleanBytes.formattedBytes)
                statRow(
                    "Last scan",
                    model.lastScanDate.map { Formatters.dateTime.string(from: $0) } ?? "Never"
                )
            }

            Divider()

            Button("Open Dashboard") {
                openWindow(id: "dashboard")
            }

            Button(model.isScanning ? "Scanning..." : "Scan Now") {
                Task { await model.scanNow() }
            }
            .disabled(model.isScanning)

            Button("Quick Clean Safe Caches") {
                model.quickCleanSafeCandidates()
            }

            Button("Settings") {
                openSettings()
            }

            Divider()

            Text("Auto scan: \(model.autoScanEnabled ? "On" : "Off")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.caption)
    }
}
