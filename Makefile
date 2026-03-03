# DeliveryRushMobile — developer convenience Makefile
# Usage: make lint | make test | make build | make coverage

PROJECT   = DeliveryRushMobile.xcodeproj
SCHEME    = DeliveryRushMobile
DEST      = platform=iOS Simulator,name=iPhone 16 Pro
DERIVED   = $(HOME)/Library/Developer/Xcode/DerivedData

.PHONY: lint test build clean coverage open

## Run SwiftLint (install via: brew install swiftlint)
lint:
	@if command -v swiftlint > /dev/null; then \
		swiftlint lint --config .swiftlint.yml; \
	else \
		echo "SwiftLint not installed. Run: brew install swiftlint"; \
		exit 1; \
	fi

## Auto-fix SwiftLint issues where possible
lint-fix:
	@if command -v swiftlint > /dev/null; then \
		swiftlint --fix --config .swiftlint.yml; \
	else \
		echo "SwiftLint not installed. Run: brew install swiftlint"; \
		exit 1; \
	fi

## Build for simulator (no signing required)
build:
	xcodebuild -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -destination '$(DEST)' \
	           -configuration Debug \
	           CODE_SIGNING_ALLOWED=NO \
	           build | xcpretty || xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' CODE_SIGNING_ALLOWED=NO build

## Run unit tests
test:
	xcodebuild -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -destination '$(DEST)' \
	           -configuration Debug \
	           CODE_SIGNING_ALLOWED=NO \
	           test | xcpretty || xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' CODE_SIGNING_ALLOWED=NO test

## Run tests and generate coverage report
coverage:
	xcodebuild -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -destination '$(DEST)' \
	           -configuration Debug \
	           CODE_SIGNING_ALLOWED=NO \
	           -enableCodeCoverage YES \
	           test | xcpretty
	@echo "Coverage report available in DerivedData"

## Clean build artifacts
clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(DERIVED)/$(SCHEME)-*/

## Open project in Xcode
open:
	open $(PROJECT)

## Show help
help:
	@grep -E '^##' Makefile | sed 's/## //'
