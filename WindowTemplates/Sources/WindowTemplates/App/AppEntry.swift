import SwiftUI

@main
struct WindowTemplatesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        Window("Window Templates", id: "main") {
            MainWindow()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Preset") {
                    appState.addPreset()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
