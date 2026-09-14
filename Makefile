output ?= .agents/interfaces
platform ?= macos
swift_sdk ?=

.PHONY: swiftinterface test
swiftinterface:
	@./scripts/generate-swiftinterfaces.sh --package-path . --output "$(output)" --platform "$(platform)" $(if $(swift_sdk),--swift-sdk "$(swift_sdk)")

test:
	swift test
