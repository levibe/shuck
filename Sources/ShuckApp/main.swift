import AppKit

// main.swift's top level isn't inferred @MainActor; assumeIsolated asserts what's
// already true (we're on the main thread, before the run loop starts).
MainActor.assumeIsolated {
	let app = NSApplication.shared
	let delegate = AppDelegate()
	app.delegate = delegate
	app.run()
}
