import SwiftUI

struct MainWindow: View {
    static let windowIdentifier = "main-window"

    @EnvironmentObject private var appState: AppState
    @State private var editingPresetID: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation {
                        columnVisibility = columnVisibility == .detailOnly
                            ? .automatic : .detailOnly
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $appState.selectedPresetID) {
                ForEach(appState.presetStore.presets) { preset in
                    if editingPresetID == preset.id, let binding = binding(for: preset) {
                        TextField("Preset Name", text: binding.name)
                            .onSubmit { editingPresetID = nil }
                            .tag(preset.id)
                    } else {
                        Text(preset.name)
                            .tag(preset.id)
                            .onTapGesture(count: 2) { editingPresetID = preset.id }
                    }
                }
                .onDelete(perform: deletePresets)
            }
            .listStyle(.sidebar)
            .toolbar(removing: .sidebarToggle)

            HStack {
                Button(action: appState.addPreset) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)

                Button(action: deleteSelected) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(selectedPreset == nil)

                Spacer()

                Button("Apply") {
                    if let preset = selectedPreset {
                        Task { await appState.windowManager.apply(preset: preset) }
                    }
                }
                .disabled(selectedPreset == nil)
            }
            .padding(8)
        }
    }

    private var detail: some View {
        Group {
            if let preset = selectedPreset,
               let binding = binding(for: preset) {
                PresetEditorView(preset: binding)
                    .onChange(of: appState.presetStore.presets) { _, _ in
                        appState.presetStore.save()
                    }
            } else {
                EmptyStateView()
            }
        }
        .padding()
    }

    private var selectedPreset: Preset? {
        guard let id = appState.selectedPresetID else { return nil }
        return appState.presetStore.presets.first { $0.id == id }
    }

    private func binding(for preset: Preset) -> Binding<Preset>? {
        guard let index = appState.presetStore.presets.firstIndex(where: { $0.id == preset.id }) else { return nil }
        return Binding(
            get: { appState.presetStore.presets[index] },
            set: { appState.presetStore.presets[index] = $0 }
        )
    }

    private func deleteSelected() {
        guard let preset = selectedPreset else { return }
        appState.deletePreset(preset)
    }

    private func deletePresets(at offsets: IndexSet) {
        appState.deletePresets(at: offsets)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No Preset Selected")
                .font(.title2)
            Text("Create a preset to start defining window layouts.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
