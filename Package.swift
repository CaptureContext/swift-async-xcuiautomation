// swift-tools-version: 6.1

import PackageDescription

let package = Package(
	name: "swift-async-xcuiautomation",
	platforms: [
		.iOS(.v17),
		.macOS(.v14)
	],
	products: [
		.library(
			name: "AsyncXCUIAutomation",
			targets: ["AsyncXCUIAutomation"],
		),
	],
	dependencies: [],
	targets: [
		.target(
			name: "AsyncXCUIAutomation",
			dependencies: [],
		),
		.testTarget(
			name: "AsyncXCUIAutomationTests",
			dependencies: [
				.target(
					name: "AsyncXCUIAutomation",
					condition: nil
				),
			],
		),
	]
)
