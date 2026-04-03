.PHONY: all build test app run clean install dmg

CONFIG ?= debug
VERSION ?= 1.0.0

all: app

build:
	swift build --configuration $(CONFIG)

test:
	swift test

app: build
	./build-app.sh $(CONFIG)

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
