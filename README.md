# swift-async-xcuiautomation

Cancellable async waits for Apple's XCUIAutomation framework.

## Table of contents

- [Motivation](#motivation)
- [Usage](#usage)
  - [Wait conditions](#wait-conditions)
  - [Timeouts and cancellation](#timeouts-and-cancellation)
  - [Pyxis integration](#pyxis-integration)
- [Development](#development)
- [Installation](#installation)
  - [Basic](#basic)
  - [Recommended](#recommended)
- [License](#license)

## Motivation

UI tests often need to wait for an element to appear, become hittable, or disappear before continuing. Apple's synchronous waits block the calling thread, even inside an async test.

`swift-async-xcuiautomation` adds async overloads that suspend between readiness checks and support task cancellation. Accessibility queries and UI interactions stay on the main actor.

The package has no third-party dependencies or application runtime hooks.

## Usage

Import `AsyncXCUIAutomation` in your UI test target and await a condition before interacting with an element:

```swift
import XCTest
import XCUIAutomation
import AsyncXCUIAutomation

internal final class EditorTests: XCTestCase {
	@MainActor
	internal func testOpenEditor() async throws {
		let app: XCUIApplication = .init()
		app.launch()
		defer { app.terminate() }

		let button = app.buttons["create"]
		let ready = try await button.wait(
			for: \.isHittable,
			toEqual: true,
			timeout: .seconds(5)
		)
		XCTAssertTrue(ready, "The create button did not become hittable")
		guard ready else { return }

		button.tap()

		let appeared = try await app.textViews["editor"].waitForExistence(
			timeout: .seconds(5)
		)
		XCTAssertTrue(appeared, "The editor did not appear")
	}
}
```

Replace the accessibility identifiers with your app's own values. Keep `XCTAssertTrue` after awaiting the result; XCTest's assertion autoclosure cannot await an operation.

> [!NOTE]
>
> Use `Duration`, such as `.seconds(5)`, to select the async overloads. Apple's existing `TimeInterval` overloads remain synchronous.

### Wait conditions

| Condition | Call |
| --- | --- |
| An element appears | `try await element.waitForExistence(timeout: .seconds(5))` |
| An element disappears | `try await element.waitForNonExistence(timeout: .seconds(5))` |
| A property reaches a value | `try await element.wait(for: \.isHittable, toEqual: true, timeout: .seconds(5))` |
| The app changes state | `try await app.wait(for: .runningForeground, timeout: .seconds(5))` |
| Several element properties match | `try await element.wait(timeout: .seconds(5)) { $0.exists && $0.isHittable }` |

Every wait accepts `pollingInterval:`, defaulting to `.milliseconds(100)`. Predicates can throw; their errors propagate to the caller. Predicates are retried, so keep them read-only and perform gestures after a successful wait.

### Timeouts and cancellation

- A satisfied condition returns `true`.
- A timeout returns `false`; it does not automatically fail the XCTest test.
- Task cancellation throws `CancellationError`.
- A negative timeout throws `AsyncWaitError.negativeTimeout`.
- A nonpositive polling interval throws `AsyncWaitError.nonPositivePollingInterval`.
- A zero timeout performs one immediate probe unless the task is already cancelled.

Waiting uses `ContinuousClock` and suspends the task between probes. Each accessibility query is still a synchronous main-actor operation. Cancellation and deadlines cannot interrupt an Apple framework query already in progress.

Launches, gestures and screenshots remain Apple's synchronous APIs. Keep operations on one app sequential, await any child tasks before the test ends, and do not move XCUI objects into detached tasks.

### Pyxis integration

The [Pyxis Swift package](https://github.com/capturecontext/pyxis-swift) uses this library for asynchronous recorder readiness checks. The packages can also be used independently. Import `AsyncXCUIAutomation` explicitly to use its extensions in your own tests. See Pyxis's [async example](https://github.com/capturecontext/pyxis-swift/blob/main/Example/UITests/AsyncDemoUITests.swift) for usage with both packages.

## Development

From the package root:

```sh
swift test
```

These tests exercise the polling engine, including timeout, cancellation and predicate errors. XCUI extensions are conditionally compiled when XCUIAutomation is importable. Use an Xcode UI test build to verify those extensions against a real app; passing the polling tests alone does not exercise Apple's accessibility system.

Public API snapshots live under `.agents/interfaces/<platform>/`. Regenerate them with:

```sh
make swiftinterface platform=macos
make swiftinterface platform=ios
```

The snapshots are generated API references, not source files to edit.

## Installation

Requires Swift 6.1 or newer, iOS 17 or macOS 14, and an Xcode UI test target where XCUIAutomation is available.

### Basic

You can add `swift-async-xcuiautomation` to an Xcode project by adding it as a package dependency.

1. Open your project's package dependencies and add a package.
2. Enter [`https://github.com/capturecontext/swift-async-xcuiautomation`](https://github.com/capturecontext/swift-async-xcuiautomation) into the package repository URL text field and select version `0.0.1`.
3. Link the **AsyncXCUIAutomation** product to your UI test target.

### Recommended

If you use SwiftPM for your project structure, add `swift-async-xcuiautomation` to your package file:

```swift
.package(
	url: "https://github.com/capturecontext/swift-async-xcuiautomation.git",
	.upToNextMinor(from: "0.0.1")
)
```

Do not forget about target dependencies:

```swift
.product(
	name: "AsyncXCUIAutomation",
	package: "swift-async-xcuiautomation"
)
```

## License

MIT, copyright 2026 CaptureContext. See [LICENSE](LICENSE).
