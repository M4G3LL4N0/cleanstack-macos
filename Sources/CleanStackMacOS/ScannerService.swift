import Foundation

struct ScannerService {
    private let fileManager = FileManager.default

    func scan() -> [CleanCandidate] {
        var results: [CleanCandidate] = []

        results.append(contentsOf: safeSystemCandidates())
        results.append(contentsOf: oldDownloadsCandidates())
        results.append(contentsOf: largeOldProjectCandidates())

        let deduped = Dictionary(grouping: results, by: { $0.path.path }).compactMap { $0.value.first }
        return deduped.sorted { $0.bytes > $1.bytes }
    }

    private func safeSystemCandidates() -> [CleanCandidate] {
        var candidates: [CleanCandidate] = []

        let home = fileManager.homeDirectoryForCurrentUser
        let derivedData = home.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
        let diagnosticReports = home.appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
        let caches = home.appendingPathComponent("Library/Caches", isDirectory: true)

        let safeTargets: [(URL, CandidateKind)] = [
            (derivedData, .derivedData),
            (diagnosticReports, .logs),
            (caches, .safeCache),
        ]

        for (url, kind) in safeTargets {
            guard fileManager.fileExists(atPath: url.path) else { continue }
            let bytes = folderSize(url)
            guard bytes > 0 else { continue }

            candidates.append(
                CleanCandidate(
                    path: url,
                    displayName: url.lastPathComponent,
                    bytes: bytes,
                    lastModified: modificationDate(url),
                    kind: kind,
                    isSafeQuickClean: true
                )
            )
        }

        return candidates
    }

    private func oldDownloadsCandidates() -> [CleanCandidate] {
        let downloads = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true)
        guard fileManager.fileExists(atPath: downloads.path) else { return [] }

        let cutoff = Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date()
        var candidates: [CleanCandidate] = []

        guard let enumerator = fileManager.enumerator(
            at: downloads,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            guard
                let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]),
                values.isRegularFile == true,
                let modified = values.contentModificationDate,
                modified < cutoff,
                let size = values.fileSize,
                size >= 250 * 1024 * 1024
            else {
                continue
            }

            candidates.append(
                CleanCandidate(
                    path: fileURL,
                    displayName: fileURL.lastPathComponent,
                    bytes: Int64(size),
                    lastModified: modified,
                    kind: .downloads,
                    isSafeQuickClean: false
                )
            )
        }

        return candidates
    }

    private func largeOldProjectCandidates() -> [CleanCandidate] {
        let home = fileManager.homeDirectoryForCurrentUser
        let candidateRoots = [
            home.appendingPathComponent("Documents", isDirectory: true),
            home.appendingPathComponent("Desktop", isDirectory: true),
            home.appendingPathComponent("Downloads", isDirectory: true),
            home.appendingPathComponent("startups", isDirectory: true)
        ]

        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        var results: [CleanCandidate] = []

        for root in candidateRoots where fileManager.fileExists(atPath: root.path) {
            guard let children = try? fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for child in children {
                guard
                    let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey]),
                    values.isDirectory == true
                else {
                    continue
                }

                let modified = modificationDate(child)
                let bytes = folderSize(child)

                guard bytes >= 2 * 1024 * 1024 * 1024 else { continue }
                guard let modified, modified < cutoff else { continue }

                let safeQuickClean = child.path.contains("/startups/") == false

                results.append(
                    CleanCandidate(
                        path: child,
                        displayName: child.lastPathComponent,
                        bytes: bytes,
                        lastModified: modified,
                        kind: .oldLargeFolder,
                        isSafeQuickClean: false && safeQuickClean
                    )
                )
            }
        }

        return results
    }

    private func folderSize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0

        for case let fileURL as URL in enumerator {
            guard
                let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                values.isRegularFile == true,
                let fileSize = values.fileSize
            else {
                continue
            }
            total += Int64(fileSize)
        }

        return total
    }

    private func modificationDate(_ url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }
}
