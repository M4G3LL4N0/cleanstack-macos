import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var candidates: [CleanCandidate] = []
    @Published var selectedCandidateIDs: Set<UUID> = []
    @Published var isScanning = false
    @Published var lastScanDate: Date?
    @Published var statusMessage = "Ready"
    @Published var autoScanEnabled = true
    @Published var autoSafeCleanEnabled = false
    @Published var intervalPresetRawValue = AutoIntervalPreset.oneHour.rawValue
    @Published var customIntervalMinutes = 60

    private let scanner = ScannerService()
    private let cleaner = CleanerService()
    private var timer: Timer?

    init() {
        loadSettings()
        startScheduler()
        Task {
            await scanNow()
        }
    }

    var intervalPreset: AutoIntervalPreset {
        get { AutoIntervalPreset(rawValue: intervalPresetRawValue) ?? .oneHour }
        set {
            intervalPresetRawValue = newValue.rawValue
            persistSettings()
            startScheduler()
        }
    }

    var currentIntervalSeconds: TimeInterval {
        intervalPreset.seconds(customMinutes: customIntervalMinutes)
    }

    var summary: ScanSummary {
        let totalBytes = candidates.reduce(Int64(0)) { $0 + $1.bytes }
        let safeBytes = candidates.filter(\.isSafeQuickClean).reduce(Int64(0)) { $0 + $1.bytes }

        return ScanSummary(
            totalCandidates: candidates.count,
            totalBytes: totalBytes,
            safeQuickCleanBytes: safeBytes,
            lastScan: lastScanDate
        )
    }

    var menuBarSymbolName: String {
        if isScanning { return "bolt.circle.fill" }
        if candidates.isEmpty { return "checkmark.circle" }
        return "externaldrive.badge.exclamationmark"
    }

    func scanNow() async {
        isScanning = true
        statusMessage = "Scanning…"

        let scanned = await Task.detached(priority: .utility) {
            ScannerService().scan()
        }.value

        candidates = scanned
        lastScanDate = Date()
        isScanning = false

        if scanned.isEmpty {
            statusMessage = "No major cleanup candidates found"
        } else {
            statusMessage = "Found \(scanned.count) candidates"
        }

        persistSettings()

        if autoSafeCleanEnabled {
            quickCleanSafeCandidates()
        }
    }

    func quickCleanSafeCandidates() {
        let safe = candidates.filter(\.isSafeQuickClean)
        guard !safe.isEmpty else {
            statusMessage = "No safe quick-clean items available"
            return
        }

        let cleaned = cleaner.quickClean(safe)
        statusMessage = "Quick cleaned \(cleaned) safe item(s)"

        Task {
            await scanNow()
        }
    }

    func trashSelectedCandidates() {
        let selected = candidates.filter { selectedCandidateIDs.contains($0.id) }
        guard !selected.isEmpty else {
            statusMessage = "No selected items"
            return
        }

        var cleaned = 0
        for candidate in selected {
            do {
                try cleaner.moveToTrash(candidate)
                cleaned += 1
            } catch {
                continue
            }
        }

        statusMessage = "Moved \(cleaned) item(s) to Trash"
        selectedCandidateIDs.removeAll()

        Task {
            await scanNow()
        }
    }

    func toggleSelection(for candidate: CleanCandidate) {
        if selectedCandidateIDs.contains(candidate.id) {
            selectedCandidateIDs.remove(candidate.id)
        } else {
            selectedCandidateIDs.insert(candidate.id)
        }
    }

    func startScheduler() {
        timer?.invalidate()
        timer = nil

        persistSettings()

        guard autoScanEnabled else { return }

        timer = Timer.scheduledTimer(withTimeInterval: currentIntervalSeconds, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.scanNow()
            }
        }
    }

    func persistSettings() {
        let defaults = UserDefaults.standard
        defaults.set(autoScanEnabled, forKey: "autoScanEnabled")
        defaults.set(autoSafeCleanEnabled, forKey: "autoSafeCleanEnabled")
        defaults.set(intervalPresetRawValue, forKey: "intervalPresetRawValue")
        defaults.set(customIntervalMinutes, forKey: "customIntervalMinutes")
        defaults.set(lastScanDate, forKey: "lastScanDate")
    }

    func loadSettings() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: "autoScanEnabled") != nil {
            autoScanEnabled = defaults.bool(forKey: "autoScanEnabled")
        }

        if defaults.object(forKey: "autoSafeCleanEnabled") != nil {
            autoSafeCleanEnabled = defaults.bool(forKey: "autoSafeCleanEnabled")
        }

        if let preset = defaults.string(forKey: "intervalPresetRawValue") {
            intervalPresetRawValue = preset
        }

        let minutes = defaults.integer(forKey: "customIntervalMinutes")
        if minutes > 0 {
            customIntervalMinutes = minutes
        }

        lastScanDate = defaults.object(forKey: "lastScanDate") as? Date
    }
}
