import Foundation
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()
    static let presetsDidChange = Notification.Name("AppState.presetsDidChange")

    let presetStore: PresetStore
    let windowManager: WindowManager
    let appCatalog: AppCatalog

    @Published var selectedPresetID: UUID?

    init() {
        self.presetStore = PresetStore()
        self.windowManager = WindowManager()
        self.appCatalog = AppCatalog()
        self.selectedPresetID = presetStore.presets.first?.id

        presetStore.$presets.sink { _ in
            NotificationCenter.default.post(name: AppState.presetsDidChange, object: nil)
        }.store(in: &cancellables)
    }

    private var cancellables: Set<AnyCancellable> = []

    func addPreset() {
        let preset = Preset(name: "New Preset", targets: [])
        presetStore.presets.append(preset)
        selectedPresetID = preset.id
        presetStore.save()
    }

    func deletePreset(_ preset: Preset) {
        presetStore.presets.removeAll { $0.id == preset.id }
        if selectedPresetID == preset.id {
            // Avoid reentrant selection changes during NSTableView delegate callbacks.
            DispatchQueue.main.async {
                self.selectedPresetID = self.presetStore.presets.first?.id
            }
        }
        presetStore.save()
    }

    func deletePresets(at offsets: IndexSet) {
        let removedIDs = offsets.compactMap { presetStore.presets[safe: $0]?.id }
        presetStore.presets.remove(atOffsets: offsets)
        if let selectedID = selectedPresetID,
           removedIDs.contains(selectedID) {
            // Avoid reentrant selection changes during NSTableView delegate callbacks.
            DispatchQueue.main.async {
                self.selectedPresetID = self.presetStore.presets.first?.id
            }
        }
        presetStore.save()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
