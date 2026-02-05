import AppKit
import ApplicationServices

final class WindowManager {
    func apply(preset: Preset) async {
        guard AccessibilityPermissions.isTrusted() else {
            AccessibilityPermissions.request()
            return
        }
        guard let screen = NSScreen.main else { return }
        // Convert visibleFrame from AppKit coords (origin bottom-left) to
        // Core Graphics / Accessibility coords (origin top-left).
        let vf = screen.visibleFrame
        let frame = CGRect(
            x: vf.origin.x,
            y: screen.frame.height - vf.origin.y - vf.height,
            width: vf.width,
            height: vf.height
        )

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
        return windows.filter { isStandardWindow($0) }
    }

    private func isStandardWindow(_ window: AXUIElement) -> Bool {
        var subrole: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subrole) == .success,
              let role = subrole as? String else { return false }
        return role == kAXStandardWindowSubrole as String
    }

    private func ensureWindowCount(app appElement: AXUIElement, pid: pid_t, needed: Int) async -> [AXUIElement] {
        var windows = getWindows(for: appElement)
        var attempts = 0
        while windows.count < needed && attempts < needed {
            guard openNewWindow(for: appElement) else { break }
            await waitForNewWindow(appElement: appElement, previousCount: windows.count)
            windows = getWindows(for: appElement)
            attempts += 1
        }
        return windows
    }

    private func openNewWindow(for appElement: AXUIElement) -> Bool {
        guard let menuItem = findMenuItem(in: appElement, titled: "New Window")
                ?? findMenuItem(in: appElement, titled: "New OS Window") else {
            return false
        }
        return AXUIElementPerformAction(menuItem, kAXPressAction as CFString) == .success
    }

    private func findMenuItem(in appElement: AXUIElement, titled target: String) -> AXUIElement? {
        var menuBarValue: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarValue) == .success,
              let menuBar = menuBarValue as! AXUIElement? else { return nil }

        for menu in axChildren(of: menuBar) {
            for item in axChildren(of: menu) {
                var titleValue: AnyObject?
                if AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &titleValue) == .success,
                   let title = titleValue as? String, title == target {
                    return item
                }
                // Check one level deeper (submenu items live inside a child menu)
                for subItem in axChildren(of: item) {
                    var subTitleValue: AnyObject?
                    if AXUIElementCopyAttributeValue(subItem, kAXTitleAttribute as CFString, &subTitleValue) == .success,
                       let subTitle = subTitleValue as? String, subTitle == target {
                        return subItem
                    }
                }
            }
        }
        return nil
    }

    private func axChildren(of element: AXUIElement) -> [AXUIElement] {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
              let children = value as? [AXUIElement] else { return [] }
        return children
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
