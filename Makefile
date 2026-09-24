# Command Line Tools' SwiftPM can't find the swift-testing framework; Xcode's can.
XCODE_DEVELOPER ?= /Applications/Xcode.app/Contents/Developer

.PHONY: test clean

test:
	DEVELOPER_DIR=$(XCODE_DEVELOPER) swift test

clean:
	swift package clean
	rm -rf build .build
