.PHONY: all build clean app run

all: app

build:
	swift build

app: build
	./build-app.sh

clean:
	swift package clean
	rm -rf .build

run: app
	open .build/arm64-apple-macosx/debug/Lucid.app

install: app
	cp -R .build/arm64-apple-macosx/debug/Lucid.app /Applications/
