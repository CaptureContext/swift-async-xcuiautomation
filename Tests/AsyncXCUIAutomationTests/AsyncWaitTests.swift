import Testing
@testable import AsyncXCUIAutomation

@Suite
@MainActor
struct AsyncWaitTests {
	@Test
	func zeroTimeoutProbesOnce() async throws {
		var probes = 0
		let result = try await pollUntil(timeout: .zero, with: .seconds(1)) {
			probes += 1
			return false
		}
		#expect(!result)
		#expect(probes == 1)
		#expect(try await pollUntil(timeout: .zero, with: .seconds(1)) { true })
	}

	@Test
	func suspendsSoOtherMainActorWorkCanSatisfyCondition() async throws {
		var ready = false
		let work = Task { @MainActor in ready = true }
		let result = try await pollUntil(timeout: .seconds(2), with: .milliseconds(1)) { ready }
		await work.value
		#expect(result)
	}

	@Test
	func timeoutDoesNotWaitForWholePollingInterval() async throws {
		let result = try await pollUntil(timeout: .milliseconds(5), with: .seconds(60)) { false }
		#expect(!result)
	}

	@Test
	func cancellationInterruptsSleep() async throws {
		var started = false
		let wait = Task { @MainActor in
			try await pollUntil(timeout: .seconds(60), with: .seconds(60)) {
				started = true
				return false
			}
		}
		while !started { await Task.yield() }
		wait.cancel()
		await #expect(throws: CancellationError.self) { try await wait.value }
	}

	@Test
	func cancelledTaskNeverProbes() async throws {
		let wait = Task { @MainActor in
			try await pollUntil(timeout: .seconds(1), with: .milliseconds(1)) {
				Issue.record("A cancelled wait probed the UI")
				return true
			}
		}
		wait.cancel()
		await #expect(throws: CancellationError.self) { try await wait.value }
	}

	@Test
	func invalidDurationsAndConditionErrorsPropagate() async throws {
		await #expect(throws: AsyncWaitError.negativeTimeout) {
			try await pollUntil(timeout: .seconds(-1), with: .seconds(1)) { true }
		}
		await #expect(throws: AsyncWaitError.nonPositivePollingInterval) {
			try await pollUntil(timeout: .seconds(1), with: .zero) { true }
		}
		await #expect(throws: AsyncWaitError.negativeTimeout) {
			try await pollUntil(timeout: .seconds(1), with: .milliseconds(1)) {
				throw AsyncWaitError.negativeTimeout
			}
		}
	}
}
