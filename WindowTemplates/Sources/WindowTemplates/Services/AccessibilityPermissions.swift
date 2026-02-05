import ApplicationServices

enum AccessibilityPermissions {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func request() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
