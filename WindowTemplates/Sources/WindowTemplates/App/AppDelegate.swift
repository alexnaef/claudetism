import AppKit
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

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

        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Failed to toggle launch at login: \(error)")
        }
        rebuildMenu()
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
        for window in NSApp.windows where window.title == "Window Templates" {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
