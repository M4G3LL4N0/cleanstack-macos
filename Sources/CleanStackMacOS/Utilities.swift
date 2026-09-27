import Foundation

enum Formatters {
    static let relativeDate: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    static let byteCount: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.isAdaptive = true
        return formatter
    }()

    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Int64 {
    var formattedBytes: String {
        Formatters.byteCount.string(fromByteCount: self)
    }
}

extension Optional where Wrapped == Date {
    var cleanstackRelativeDescription: String {
        guard let date = self else { return "Unknown" }
        return Formatters.relativeDate.localizedString(for: date, relativeTo: Date())
    }
}
