import AppKit
import ApplicationServices
import Carbon.HIToolbox
import CoreGraphics
import ServiceManagement
import ShuckCore

/// Shuck has no UI of its own: a global hotkey and a right-click service, both "Shuck and Paste".
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
	private var shuckedChangeCount: Int?
	private var hotKeyRef: EventHotKeyRef?
	private var accessibilityPrompted = false

	func applicationDidFinishLaunching(_ notification: Notification) {
		registerHotKey()
		NSApp.servicesProvider = self
		registerLoginItemOnce()
	}

	// MARK: - Clipboard

	/// Replaces the clipboard's text with its shucked form; false (after a beep) when it holds no text.
	private func shuckPasteboard() -> Bool {
		let pasteboard = NSPasteboard.general
		// Already our output (e.g. pasting twice): shucking again could merge lines the first pass kept apart.
		if pasteboard.changeCount == shuckedChangeCount {
			return true
		}
		guard let original = pasteboard.string(forType: .string) else {
			NSSound.beep()
			return false
		}
		pasteboard.clearContents()
		pasteboard.setString(shuck(original), forType: .string)
		shuckedChangeCount = pasteboard.changeCount
		return true
	}

	// MARK: - Service (right-click; NSServices in Info.plist)

	/// Hands the shucked clipboard back to the app, which inserts it where the user right-clicked.
	@objc func shuckAndPaste(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
		guard shuckPasteboard(), let text = NSPasteboard.general.string(forType: .string) else { return }
		pboard.clearContents()
		pboard.setString(text, forType: .string)
	}

	// MARK: - Launch at login

	/// Only on first launch, so switching it off in System Settings sticks.
	private func registerLoginItemOnce() {
		let key = "loginItemRegistered"
		guard !UserDefaults.standard.bool(forKey: key) else { return }
		do {
			try SMAppService.mainApp.register()
			UserDefaults.standard.set(true, forKey: key)
		} catch {
			NSLog("Shuck: couldn't add the login item: \(error)")
		}
	}

	// MARK: - Global hotkey (Carbon; needs no permission to register)

	private func registerHotKey() {
		let hotKeyID = EventHotKeyID(signature: OSType(0x7368636B), id: 1) // 'shck'
		var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

		InstallEventHandler(
			GetApplicationEventTarget(),
			{ _, _, userData in
				guard let userData else { return noErr }
				Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue().hotKeyPressed()
				return noErr
			},
			1,
			&eventType,
			Unmanaged.passUnretained(self).toOpaque(),
			nil
		)

		let modifiers = UInt32(cmdKey | optionKey | controlKey)
		RegisterEventHotKey(UInt32(kVK_ANSI_V), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
	}

	private func hotKeyPressed() {
		guard shuckPasteboard() else { return }
		guard ensureAccessibilityTrust() else { return }
		postPasteKeystroke()
	}

	private func ensureAccessibilityTrust() -> Bool {
		if AXIsProcessTrusted() {
			return true
		}
		// Prompt once per launch, then beep: the pasteboard is already shucked either way,
		// so the user can still paste with a real ⌘V, but a silent hotkey reads as broken.
		if accessibilityPrompted {
			NSSound.beep()
		} else {
			accessibilityPrompted = true
			let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
			AXIsProcessTrustedWithOptions(options)
		}
		return false
	}

	private func postPasteKeystroke() {
		guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
		let vKey = CGKeyCode(kVK_ANSI_V)
		guard
			let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
			let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
		else {
			return
		}
		// Set flags explicitly: the user is still physically holding ⌃⌥ from the hotkey chord,
		// and the synthetic event must carry only ⌘ for the target app to see a plain paste.
		keyDown.flags = .maskCommand
		keyUp.flags = .maskCommand
		keyDown.post(tap: .cgAnnotatedSessionEventTap)
		keyUp.post(tap: .cgAnnotatedSessionEventTap)
	}
}
