/// Suspends between probes. A probe itself remains synchronous on the main actor.
@MainActor
internal func pollUntil(
	timeout: Duration,
	with interval: Duration,
	condition: @MainActor () throws -> Bool
) async throws -> Bool {
	guard timeout >= .zero else { throw AsyncWaitError.negativeTimeout }
	guard interval > .zero else { throw AsyncWaitError.nonPositivePollingInterval }
	try Task.checkCancellation()

	let clock = ContinuousClock()
	let deadline = clock.now.advanced(by: timeout)

	while true {
		let satisfied = try condition()
		try Task.checkCancellation()
		if satisfied { return true }
		guard clock.now < deadline else { return false }

		try await clock.sleep(until: min(clock.now.advanced(by: interval), deadline))
		try Task.checkCancellation()
		guard clock.now < deadline else { return false }
	}
}
