#if canImport(XCUIAutomation)
import XCUIAutomation

extension XCUIApplication {
	@MainActor
	public func wait(
		for state: XCUIApplication.State,
		timeout: Duration,
		pollingInterval: Duration = .milliseconds(100)
	) async throws -> Bool {
		try await pollUntil(timeout: timeout, with: pollingInterval) { self.state == state }
	}
}
#endif
