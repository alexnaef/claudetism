import SwiftUI

struct PresetEditorView: View {
    @Binding var preset: Preset
    @State private var selectedTargetID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("Preset Name", text: $preset.name)
                    .textFieldStyle(.roundedBorder)
                Spacer()
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Targets")
                        .font(.headline)
                    List(selection: $selectedTargetID) {
                        ForEach(preset.targets) { target in
                            Text(target.appBundleID.isEmpty ? "(No App)" : target.appBundleID)
                                .tag(target.id)
                        }
                        .onDelete(perform: deleteTargets)
                    }
                    HStack {
                        Button("Add Target") {
                            let target = Target(appBundleID: "", rect: NormalizedRect(x: 0, y: 0, width: 0.5, height: 0.5))
                            preset.targets.append(target)
                            selectedTargetID = target.id
                        }
                        .buttonStyle(.bordered)

                        Button("Remove") {
                            deleteSelectedTarget()
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedTarget == nil)
                    }
                }
                .frame(width: 260)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Layout")
                        .font(.headline)

                    if let binding = selectedTargetBinding {
                        TargetEditorView(target: binding)
                    } else {
                        Text("Select a target to edit its layout.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var selectedTarget: Target? {
        guard let id = selectedTargetID else { return nil }
        return preset.targets.first { $0.id == id }
    }

    private var selectedTargetBinding: Binding<Target>? {
        guard let id = selectedTargetID,
              let index = preset.targets.firstIndex(where: { $0.id == id }) else { return nil }
        return $preset.targets[index]
    }

    private func deleteSelectedTarget() {
        guard let target = selectedTarget else { return }
        preset.targets.removeAll { $0.id == target.id }
        selectedTargetID = preset.targets.first?.id
    }

    private func deleteTargets(at offsets: IndexSet) {
        preset.targets.remove(atOffsets: offsets)
        selectedTargetID = preset.targets.first?.id
    }
}

private struct TargetEditorView: View {
    @Binding var target: Target

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("App Bundle ID (e.g. com.apple.Safari)", text: $target.appBundleID)
                .textFieldStyle(.roundedBorder)

            GridEditorView(rect: $target.rect)
                .frame(maxWidth: .infinity, maxHeight: 360)

            HStack {
                Text("X: \(target.rect.x, specifier: "%.2f")  Y: \(target.rect.y, specifier: "%.2f")")
                Spacer()
                Text("W: \(target.rect.width, specifier: "%.2f")  H: \(target.rect.height, specifier: "%.2f")")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
