import Foundation
import Combine

final class AppState: ObservableObject {
    static let shared = AppState()
    static let presetsDidChange = Notification.Name("AppState.presetsDidChange")

    let presetStore: PresetStore
    let windowManager: WindowManager

    @Published var selectedPresetID: UUID?

    init() {
        self.presetStore = PresetStore()
        self.windowManager = WindowManager()
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
            selectedPresetID = presetStore.presets.first?.id
        }
        presetStore.save()
    }
}
