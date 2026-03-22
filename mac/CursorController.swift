import AppKit
import Foundation

@MainActor
final class CursorController: ObservableObject {
    @Published private(set) var hasAccessibilityPermission = false
    @Published var macSensitivity: Double = 1.0

    private let maxStepPerMessage: CGFloat = 140
    private var displayBounds: CGRect = .null

    func requestAccessibilityIfNeeded() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [promptKey: true] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    func refreshPermissionStatus() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [promptKey: false] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)
    }

    func apply(deltaX: Double, deltaY: Double) {
        guard hasAccessibilityPermission else { return }

        let clampedDX = clamp(CGFloat(deltaX), min: -maxStepPerMessage, max: maxStepPerMessage) * macSensitivity
        let clampedDY = clamp(CGFloat(deltaY), min: -maxStepPerMessage, max: maxStepPerMessage) * macSensitivity

        let current = CGEvent(source: nil)?.location ?? .zero
        refreshDisplayBoundsIfNeeded()
        let nextPoint = CGPoint(
            x: clamp(current.x + clampedDX, min: displayBounds.minX, max: displayBounds.maxX),
            y: clamp(current.y + clampedDY, min: displayBounds.minY, max: displayBounds.maxY)
        )

        CGWarpMouseCursorPosition(nextPoint)
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    func click(button: MouseButton) {
        guard hasAccessibilityPermission else { return }
        let location = CGEvent(source: nil)?.location ?? .zero

        let downType: CGEventType
        let upType: CGEventType
        let cgButton: CGMouseButton
        switch button {
        case .left:
            downType = .leftMouseDown
            upType = .leftMouseUp
            cgButton = .left
        case .right:
            downType = .rightMouseDown
            upType = .rightMouseUp
            cgButton = .right
        }

        let source = CGEventSource(stateID: .hidSystemState)
        let mouseDown = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: location, mouseButton: cgButton)
        let mouseUp = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: location, mouseButton: cgButton)
        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
    }

    func type(text: String) {
        guard hasAccessibilityPermission else { return }
        guard !text.isEmpty else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
        down?.keyboardSetUnicodeString(stringLength: text.utf16.count, unicodeString: Array(text.utf16))
        up?.keyboardSetUnicodeString(stringLength: text.utf16.count, unicodeString: Array(text.utf16))
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    func pressKey(code: UInt16, isDown: Bool) {
        guard hasAccessibilityPermission else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(code), keyDown: isDown)
        event?.post(tap: .cghidEventTap)
    }

    private func refreshDisplayBoundsIfNeeded() {
        guard displayBounds.isNull else { return }

        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success else {
            displayBounds = CGRect(x: 0, y: 0, width: 9999, height: 9999)
            return
        }

        var ids = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &ids, &displayCount) == .success else {
            displayBounds = CGRect(x: 0, y: 0, width: 9999, height: 9999)
            return
        }

        displayBounds = ids.reduce(CGRect.null) { partialResult, id in
            partialResult.union(CGDisplayBounds(id))
        }
    }

    private func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        Swift.max(min, Swift.min(max, value))
    }
}
