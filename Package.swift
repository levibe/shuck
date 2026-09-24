// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "Shuck",
	platforms: [.macOS(.v13)],
	products: [
		.library(name: "ShuckCore", targets: ["ShuckCore"]),
	],
	targets: [
		.target(name: "ShuckCore"),
		.testTarget(
			name: "ShuckCoreTests",
			dependencies: ["ShuckCore"],
			resources: [.copy("Fixtures")]
		),
	]
)
