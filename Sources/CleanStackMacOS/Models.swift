import Foundation

enum CandidateKind: String, Codable, CaseIterable, Identifiable {
    case safeCache = "Safe Cache"
    case oldLargeFile = "Old Large File"
    case oldLargeFolder = "Old Large Folder"
    case derivedData = "Derived Data"
    case logs = "Logs"
    case downloads = "Downloads"

    var id: String { rawValue }
}

struct CleanCandidate: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let displayName: String
    let bytes: Int64
    let lastModified: Date?
    let kind: CandidateKind
    let isSafeQuickClean: Bool

    init(
        id: UUID = UUID(),
        path: URL,
        displayName: String,
        bytes: Int64,
        lastModified: Date?,
        kind: CandidateKind,
        isSafeQuickClean: Bool
    ) {
        self.id = id
        self.path = path
        self.displayName = displayName
        self.bytes = bytes
        self.lastModified = lastModified
        self.kind = kind
        self.isSafeQuickClean = isSafeQuickClean
    }
}

enum AutoIntervalPreset: String, CaseIterable, Identifiable {
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case sixHours = "6h"
    case oneDay = "24h"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fifteenMinutes: return "Every 15 minutes"
        case .oneHour: return "Every hour"
        case .sixHours: return "Every 6 hours"
        case .oneDay: return "Every 24 hours"
        case .custom: return "Custom"
        }
    }

    func seconds(customMinutes: Int) -> TimeInterval {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .oneHour: return 60 * 60
        case .sixHours: return 6 * 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .custom: return max(5, customMinutes) * 60
        }
    }
}

struct ScanSummary {
    let totalCandidates: Int
    let totalBytes: Int64
    let safeQuickCleanBytes: Int64
    let lastScan: Date?
}
