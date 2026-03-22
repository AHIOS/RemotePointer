# RemotePointer

RemotePointer is a lightweight Apple-platform remote control app:
- iPhone app acts as a trackpad.
- macOS menu bar app receives input on the same local network.
- Supports pointer movement plus left/right click.

## Features

- Local discovery and connection via `MultipeerConnectivity`
- Smooth pointer movement with adjustable sensitivity
- Left click and right click from iPhone gestures/buttons
- macOS menu bar host app with connection and permission status

## Project Structure

- `ios/` — iPhone SwiftUI app
- `mac/` — macOS menu bar app
- `shared/` — protocol + transport layer used by both targets
- `tests/` — unit tests for protocol and pointer scaling

## Requirements

- macOS 14+
- iOS 17+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Setup

1. Install XcodeGen:
   - `brew install xcodegen`
2. From the repository root, generate project files:
   - `xcodegen generate`
3. Open the project:
   - `open RemotePointer.xcodeproj`

## Run

1. Run `RemotePointerMac` on your Mac.
2. Grant Accessibility permission when prompted.
3. Run `RemotePointeriOS` on your iPhone.
4. Ensure both devices are on the same Wi-Fi network.
5. Use the iPhone trackpad area to move/click.

## Usage

- Drag: move pointer
- One-finger double tap: left click
- Two-finger tap: right click
- Keyboard panel: send typed text plus Enter/Backspace

## Notes

- This version is local-network only (no internet relay).
- Keyboard support currently includes basic text and key actions.

## Development Note

This project started as a quick AI-assisted vibe-coding experiment to build something useful.
The code was iterated with AI help and then manually reviewed and tested.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

## Contributing

See `CONTRIBUTING.md` for the lightweight branching strategy and PR checklist.
