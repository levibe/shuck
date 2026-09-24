APP := build/Shuck.app
ZIP := build/Shuck.zip
ICON := build/AppIcon.icns
ARCHS := arm64 x86_64
# The ad-hoc default changes with every build, which voids the Accessibility grant;
# pass a stable identity (a self-signed Code Signing certificate works) to keep it.
SIGN_IDENTITY ?= -
# Command Line Tools' SwiftPM can't find the swift-testing framework; Xcode's can.
XCODE_DEVELOPER ?= /Applications/Xcode.app/Contents/Developer

.PHONY: build test install dist clean

build: $(ICON)
	swift build -c release --product shuck
	for arch in $(ARCHS); do swift build -c release --arch $$arch --product ShuckApp || exit 1; done
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	lipo -create -output $(APP)/Contents/MacOS/Shuck $(foreach arch,$(ARCHS),.build/$(arch)-apple-macosx/release/ShuckApp)
	cp Resources/Info.plist $(APP)/Contents/Info.plist
	cp $(ICON) $(APP)/Contents/Resources/AppIcon.icns
	codesign --force --sign "$(SIGN_IDENTITY)" $(APP)

$(ICON): Scripts/make-icon.swift
	rm -rf build/AppIcon.iconset
	swift Scripts/make-icon.swift build/AppIcon.iconset
	iconutil -c icns -o $@ build/AppIcon.iconset

test:
	DEVELOPER_DIR=$(XCODE_DEVELOPER) swift test

install: build
	-osascript -e 'quit app "Shuck"'
	rm -rf ~/Applications/Shuck.app
	mkdir -p ~/Applications
	cp -R $(APP) ~/Applications/
	# Services only list apps Launch Services knows about; a fresh copy isn't registered until launched.
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/Shuck.app
	/System/Library/CoreServices/pbs -update
	mkdir -p ~/.local/bin
	# Not .build/release: SwiftPM points that at the last --arch built, which lacks the CLI.
	cp "$$(swift build -c release --show-bin-path)/shuck" ~/.local/bin/shuck

dist: build
	rm -f $(ZIP)
	ditto -c -k --keepParent $(APP) $(ZIP)

clean:
	swift package clean
	rm -rf build .build
