import AppKit
import ApplicationServices

final class WindowManager {
    func apply(preset: Preset) {
        guard AccessibilityPermissions.isTrusted() else {
            AccessibilityPermissions.request()
            return
        }
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame

        for target in preset.targets {
            guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: target.appBundleID).first else {
                continue
            }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            guard let window = focusedWindow(for: appElement) else { continue }
            let rect = target.rect.toCGRect(in: frame)
            setFrame(window: window, rect: rect)
        }
    }

    private func focusedWindow(for appElement: AXUIElement) -> AXUIElement? {
        var focused: AnyObject?
        let focusedResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focused)
        if focusedResult == .success, let window = focused {
            return (window as! AXUIElement)
        }
        var windows: AnyObject?
        let windowsResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows)
        if windowsResult == .success, let array = windows as? [AXUIElement], let first = array.first {
            return first
        }
        return nil
    }

    private func setFrame(window: AXUIElement, rect: CGRect) {
        let position = CGPoint(x: rect.origin.x, y: rect.origin.y)
        let size = CGSize(width: rect.size.width, height: rect.size.height)

        var pos = position
        var sz = size

        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &pos)!)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &sz)!)
    }
}
