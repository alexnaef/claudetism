import AppKit
import Foundation

final class AppCatalog: NSObject, ObservableObject {
    @Published private(set) var apps: [AppInfo] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?

    private let query = NSMetadataQuery()
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        configureQuery()
        start()
    }

    deinit {
        stop()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func start() {
        guard !query.isStarted else { return }
        isLoading = true
        query.start()
    }

    func stop() {
        guard query.isStarted else { return }
        query.stop()
    }

    func filteredApps(query text: String) -> [AppInfo] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return apps }
        let needle = trimmed.lowercased()
        return apps.filter { app in
            app.displayName.lowercased().contains(needle)
            || app.bundleID.lowercased().contains(needle)
            || app.url.lastPathComponent.lowercased().contains(needle)
        }
    }

    private func configureQuery() {
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
        query.predicate = NSPredicate(format: "%K == %@", kMDItemContentType as String, "com.apple.application-bundle")

        let didFinish = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: .main
        ) { [weak self] _ in
            self?.refreshResults()
        }

        let didUpdate = NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query,
            queue: .main
        ) { [weak self] _ in
            self?.refreshResults()
        }

        observers = [didFinish, didUpdate]
    }

    private func refreshResults() {
        let results = query.results.compactMap { $0 as? NSMetadataItem }
        let resolved = resolveApps(from: results)
        apps = resolved.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        isLoading = false
        lastError = apps.isEmpty ? "No applications found." : nil
    }

    private func resolveApps(from items: [NSMetadataItem]) -> [AppInfo] {
        var byBundleID: [String: AppInfo] = [:]

        for item in items {
            guard let path = item.value(forAttribute: kMDItemPath as String) as? String else { continue }
            let url = URL(fileURLWithPath: path)
            guard let bundle = Bundle(url: url), let bundleID = bundle.bundleIdentifier else { continue }

            let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent

            let info = AppInfo(bundleID: bundleID, displayName: displayName, url: url)

            if let existing = byBundleID[bundleID] {
                if prefer(info, over: existing) {
                    byBundleID[bundleID] = info
                }
            } else {
                byBundleID[bundleID] = info
            }
        }

        return Array(byBundleID.values)
    }

    private func prefer(_ candidate: AppInfo, over existing: AppInfo) -> Bool {
        let candidateScore = preferenceScore(for: candidate.url)
        let existingScore = preferenceScore(for: existing.url)
        if candidateScore != existingScore { return candidateScore > existingScore }
        return candidate.url.path.count < existing.url.path.count
    }

    private func preferenceScore(for url: URL) -> Int {
        let path = url.path
        if path.hasPrefix("/Applications/") { return 3 }
        if path.hasPrefix("/System/Applications/") { return 2 }
        if path.hasPrefix("/Applications/Utilities/") { return 1 }
        return 0
    }
}
