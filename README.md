# Clipboard History

A lightweight macOS menu bar app that keeps a searchable history of everything you copy.

## Features

- Lives in the menu bar — no dock icon, no clutter
- Automatically saves your clipboard history as you copy
- Search through past items instantly
- Click any item to copy it again (and the popover closes for you)
- Configurable history size and max item length
- Light / Dark / System appearance
- Optional launch at login

## Requirements

- macOS 26 or later
- Swift 6.2 toolchain (Xcode or Command Line Tools)

## Build & Run

Build and install the app into your Applications folder:

```bash
./build.sh
```

This compiles a release build, copies it to `~/Applications/Clipboard History.app`, code-signs it, and launches it. Click the clipboard icon in the menu bar to open it.

## Development

Build without installing:

```bash
swift build
```

Run the test suite:

```bash
swift test
```

## Project Structure

```
Sources/
  ClipboardHistoryCore/   Platform-agnostic history logic (no UI, fully unit tested)
  ClipboardHistory/       SwiftUI menu bar app (views, settings, app entry point)
Tests/
  ClipboardHistoryCoreTests/  Tests for the core logic
  ClipboardHistoryTests/      Tests for the app layer
```

## How It Works

The app polls the system pasteboard for changes and stores new text entries locally in `~/Library/Application Support/ClipboardHistory/history.json`. Nothing leaves your machine.
