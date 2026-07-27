.PHONY: all build test app run clean install dmg

CONFIG ?= debug
VERSION ?= 1.1.0

all: app

build:
	swift build --configuration $(CONFIG)

# XCTest requires the full Xcode toolchain (not Command Line Tools alone).
test:
	@if ! xcrun --find xctest >/dev/null 2>&1; then \
		echo "error: XCTest is unavailable. Install full Xcode and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2; \
		exit 1; \
	fi
	swift test

app: build
	./build-app.sh $(CONFIG) $(VERSION)

run: app
	@BIN_PATH=$$(swift build --configuration $(CONFIG) --show-bin-path); \
	open "$$BIN_PATH/Lucid.app"

install: app
	BIN_PATH="$$(swift build --configuration $(CONFIG) --show-bin-path)" && \
	cp -R "$$BIN_PATH/Lucid.app" /Applications/

dmg:
	./create-dmg.sh $(CONFIG) $(VERSION)

clean:
	swift package clean
	rm -rf .build dist
