#if canImport(XCUIAutomation)
import XCUIAutomation

extension XCUIElement {
	/// Returns false on timeout and throws on cancellation. Zero timeout performs one probe.
	@MainActor
	public func waitForExistence(
		timeout: Duration,
		pollingInterval: Duration = .milliseconds(100)
	) async throws -> Bool {
		try await wait(timeout: timeout, pollingInterval: pollingInterval) { $0.exists }
	}

	@MainActor
	public func waitForNonExistence(
		timeout: Duration,
		pollingInterval: Duration = .milliseconds(100)
	) async throws -> Bool {
		try await wait(timeout: timeout, pollingInterval: pollingInterval) { !$0.exists }
	}

	@MainActor
	public func wait<Value: Equatable>(
		for keyPath: KeyPath<XCUIElement, Value>,
		toEqual value: Value,
		timeout: Duration,
		pollingInterval: Duration = .milliseconds(100)
	) async throws -> Bool {
		try await wait(timeout: timeout, pollingInterval: pollingInterval) { $0[keyPath: keyPath] == value }
	}

	/// The condition must only read state; interactions belong after a successful wait.
	@MainActor
	public func wait(
		timeout: Duration,
		pollingInterval: Duration = .milliseconds(100),
		until condition: @MainActor (XCUIElement) throws -> Bool
	) async throws -> Bool {
		try await pollUntil(timeout: timeout, with: pollingInterval) { try condition(self) }
	}
}
#endif
