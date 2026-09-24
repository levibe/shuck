// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "Shuck",
	platforms: [.macOS(.v13)],
	products: [
		.executable(name: "shuck", targets: ["ShuckCLI"]),
		.library(name: "ShuckCore", targets: ["ShuckCore"]),
	],
	targets: [
		.target(name: "ShuckCore"),
		.executableTarget(name: "ShuckCLI", dependencies: ["ShuckCore"]),
		.testTarget(
			name: "ShuckCoreTests",
			dependencies: ["ShuckCore"],
			resources: [.copy("Fixtures")]
		),
	]
)
