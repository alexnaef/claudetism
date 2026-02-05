import SwiftUI

struct PresetEditorView: View {
    @Binding var preset: Preset
    @State private var selectedTargetID: UUID?
    @EnvironmentObject private var appState: AppState

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
                        ForEach($preset.targets) { $target in
                            Text(targetDisplayName(for: target.wrappedValue))
                                .tag(target.id.wrappedValue)
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
                            .environmentObject(appState)
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

    private func targetDisplayName(for target: Target) -> String {
        if target.appBundleID.isEmpty {
            return "(No App)"
        }
        if let match = appState.appCatalog.apps.first(where: { $0.bundleID == target.appBundleID }) {
            return match.displayName
        }
        return target.appBundleID
    }
}

private struct TargetEditorView: View {
    @Binding var target: Target
    @EnvironmentObject private var appState: AppState
    @State private var appQuery: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("App")
                    .font(.headline)

                TextField("Search apps or paste bundle ID", text: $appQuery)
                    .textFieldStyle(.roundedBorder)

                AppResultsList(
                    apps: appState.appCatalog.filteredApps(query: appQuery),
                    isLoading: appState.appCatalog.isLoading,
                    query: appQuery,
                    onSelect: { app in
                        target.appBundleID = app.bundleID
                        appQuery = ""
                    }
                )
                .frame(maxHeight: 180)

                TextField("Bundle ID", text: $target.appBundleID)
                    .textFieldStyle(.roundedBorder)
            }

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

private struct AppResultsList: View {
    let apps: [AppInfo]
    let isLoading: Bool
    let query: String
    let onSelect: (AppInfo) -> Void

    var body: some View {
        Group {
            if isLoading && apps.isEmpty {
                Text("Indexing applications…")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if apps.isEmpty && !query.isEmpty {
                Text("No matches.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if apps.isEmpty {
                Text("Start typing to search installed apps.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(apps) { app in
                    Button {
                        onSelect(app)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.displayName)
                            Text(app.bundleID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
    }
}
