import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 14) {
                Text("CleanStack Dashboard")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 8) {
                    metricCard("Candidates", "\(model.summary.totalCandidates)")
                    metricCard("Recoverable", model.summary.totalBytes.formattedBytes)
                    metricCard("Safe quick clean", model.summary.safeQuickCleanBytes.formattedBytes)
                    metricCard(
                        "Last scan",
                        model.lastScanDate.map { Formatters.dateTime.string(from: $0) } ?? "Never"
                    )
                }

                Divider()

                Button(model.isScanning ? "Scanning..." : "Scan Now") {
                    Task { await model.scanNow() }
                }
                .disabled(model.isScanning)

                Button("Quick Clean Safe Caches") {
                    model.quickCleanSafeCandidates()
                }

                Button("Trash Selected") {
                    model.trashSelectedCandidates()
                }
                .disabled(model.selectedCandidateIDs.isEmpty)

                Spacer()

                Text(model.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(minWidth: 250)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Candidates")
                        .font(.title3.bold())
                    Spacer()
                    Text("\(model.candidates.count) found")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()

                Divider()

                List(model.candidates, id: \.id, selection: .constant(nil)) {
                    candidate in
                    CandidateRow(
                        candidate: candidate,
                        isSelected: model.selectedCandidateIDs.contains(candidate.id),
                        onToggle: {
                            model.toggleSelection(for: candidate)
                        }
                    )
                }
                .listStyle(.inset)
            }
        }
    }

    private func metricCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CandidateRow: View {
    let candidate: CleanCandidate
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(candidate.displayName)
                        .font(.headline)
                    Spacer()
                    Text(candidate.bytes.formattedBytes)
                        .font(.subheadline.weight(.semibold))
                }

                Text(candidate.kind.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(candidate.path.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    Text("Modified \(candidate.lastModified.cleanstackRelativeDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if candidate.isSafeQuickClean {
                        Text("Safe quick clean")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.16))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
