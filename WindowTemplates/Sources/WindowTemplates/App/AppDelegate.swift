import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "rectangle.grid.2x2", accessibilityDescription: "Window Templates")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Manage Presets…", action: #selector(openMainWindow), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildMenu), name: AppState.presetsDidChange, object: nil)
        rebuildMenu()
    }

    @objc private func rebuildMenu() {
        guard let menu = statusItem?.menu else { return }
        menu.removeAllItems()

        let presets = AppState.shared.presetStore.presets
        if presets.isEmpty {
            let emptyItem = NSMenuItem(title: "No Presets", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for preset in presets {
                let item = NSMenuItem(title: preset.name, action: #selector(applyPreset(_:)), keyEquivalent: "")
                item.representedObject = preset.id.uuidString
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Manage Presets…", action: #selector(openMainWindow), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let idString = sender.representedObject as? String,
              let id = UUID(uuidString: idString),
              let preset = AppState.shared.presetStore.presets.first(where: { $0.id == id }) else {
            return
        }
        Task { await AppState.shared.windowManager.apply(preset: preset) }
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.identifier?.rawValue == MainWindow.windowIdentifier {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.identifier = NSUserInterfaceItemIdentifier(MainWindow.windowIdentifier)
        window.title = "Window Templates"
        window.center()
        window.contentView = NSHostingView(rootView: MainWindow().environmentObject(AppState.shared))
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
