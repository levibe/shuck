// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "Shuck",
	platforms: [.macOS(.v13)],
	products: [
		.executable(name: "shuck", targets: ["ShuckCLI"]),
		.executable(name: "ShuckApp", targets: ["ShuckApp"]),
		.library(name: "ShuckCore", targets: ["ShuckCore"]),
	],
	targets: [
		.target(name: "ShuckCore"),
		.executableTarget(name: "ShuckCLI", dependencies: ["ShuckCore"]),
		.executableTarget(
			name: "ShuckApp",
			dependencies: ["ShuckCore"],
			// Carbon's hotkey C-callback interop (unretained global CFStringRef options,
			// @convention(c) closures) fights Swift 6 strict concurrency; the app code
			// itself stays @MainActor by convention regardless.
			swiftSettings: [.swiftLanguageMode(.v5)]
		),
		.testTarget(
			name: "ShuckCoreTests",
			dependencies: ["ShuckCore"],
			resources: [.copy("Fixtures")]
		),
	]
)
