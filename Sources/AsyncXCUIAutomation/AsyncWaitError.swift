public enum AsyncWaitError: Error, Equatable, Sendable {
	case negativeTimeout
	case nonPositivePollingInterval
}
