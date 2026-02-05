import SwiftUI

@main
struct WindowTemplatesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup("Window Templates") {
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
