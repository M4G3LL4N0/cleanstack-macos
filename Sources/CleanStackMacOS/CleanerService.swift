import Foundation

struct CleanerService {
    private let fileManager = FileManager.default

    @discardableResult
    func moveToTrash(_ candidate: CleanCandidate) throws -> URL {
        var trashedURL: NSURL?
        try fileManager.trashItem(at: candidate.path, resultingItemURL: &trashedURL)
        return (trashedURL as URL?) ?? candidate.path
    }

    func quickClean(_ candidates: [CleanCandidate]) -> Int {
        var cleaned = 0

        for candidate in candidates where candidate.isSafeQuickClean {
            do {
                try moveToTrash(candidate)
                cleaned += 1
            } catch {
                continue
            }
        }

        return cleaned
    }
}
