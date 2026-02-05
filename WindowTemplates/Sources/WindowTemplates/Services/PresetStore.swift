import Foundation
import Combine

final class PresetStore: ObservableObject {
    @Published var presets: [Preset] = []

    private let url: URL

    init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("WindowTemplates", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        self.url = directory.appendingPathComponent("presets.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: url) else {
            presets = []
            return
        }
        do {
            presets = try JSONDecoder().decode([Preset].self, from: data)
        } catch {
            presets = []
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: url, options: [.atomic])
        } catch {
            // Ignore for MVP
        }
    }
}
