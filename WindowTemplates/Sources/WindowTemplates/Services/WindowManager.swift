import AppKit
import ApplicationServices

final class WindowManager {
    func apply(preset: Preset) async {
        guard AccessibilityPermissions.isTrusted() else {
            AccessibilityPermissions.request()
            return
        }
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame

        let grouped = Dictionary(grouping: preset.targets, by: \.appBundleID)

        for (bundleID, targets) in grouped {
            guard let app = await launchAppIfNeeded(bundleID: bundleID) else { continue }
            await waitForAppReady(app)

            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            let windows = await ensureWindowCount(app: appElement, pid: app.processIdentifier, needed: targets.count)

            for (i, target) in targets.enumerated() {
                guard i < windows.count else { break }
                let rect = target.rect.toCGRect(in: frame)
                setFrame(window: windows[i], rect: rect)
            }
        }
    }

    // MARK: - Launch

    private func launchAppIfNeeded(bundleID: String) async -> NSRunningApplication? {
        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            return running
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        do {
            return try await NSWorkspace.shared.openApplication(at: url, configuration: config)
        } catch {
            return nil
        }
    }

    private func waitForAppReady(_ app: NSRunningApplication) async {
        let deadline = Date().addingTimeInterval(10)
        while !app.isFinishedLaunching && Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }

    // MARK: - Windows

    private func getWindows(for appElement: AXUIElement) -> [AXUIElement] {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        guard result == .success, let windows = value as? [AXUIElement] else { return [] }
        return windows
    }

    private func ensureWindowCount(app appElement: AXUIElement, pid: pid_t, needed: Int) async -> [AXUIElement] {
        var windows = getWindows(for: appElement)
        var attempts = 0
        while windows.count < needed && attempts < needed {
            openNewWindow(for: pid)
            await waitForNewWindow(appElement: appElement, previousCount: windows.count)
            windows = getWindows(for: appElement)
            attempts += 1
        }
        return windows
    }

    private func openNewWindow(for pid: pid_t) {
        let source = CGEventSource(stateID: .hidSystemState)
        // Virtual key 0x2E = 'N'
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x2E, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x2E, keyDown: false) else { return }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }

    private func waitForNewWindow(appElement: AXUIElement, previousCount: Int) async {
        let deadline = Date().addingTimeInterval(5)
        while getWindows(for: appElement).count <= previousCount && Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }

    // MARK: - Positioning

    private func setFrame(window: AXUIElement, rect: CGRect) {
        let position = CGPoint(x: rect.origin.x, y: rect.origin.y)
        let size = CGSize(width: rect.size.width, height: rect.size.height)

        var pos = position
        var sz = size

        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &pos)!)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &sz)!)
    }
}
