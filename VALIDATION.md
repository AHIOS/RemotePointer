# Validation Checklist

## What was verified in this environment

- Project structure and source files were created as planned.
- Swift source organization for iOS, macOS, and shared modules is complete.
- No editor lint diagnostics are present in created files.

## What must be verified on real devices

1. Install XcodeGen and generate project:
   - `brew install xcodegen`
   - `cd <path-to-your-cloned-repo>`
   - `xcodegen generate`
2. Open `RemotePointer.xcodeproj`.
3. Run `RemotePointerMac` target on your Mac.
4. Grant Accessibility permission when prompted.
5. Run `RemotePointeriOS` target on your iPhone (same Wi-Fi as Mac).

## Manual test matrix

- [ ] iPhone auto-discovers Mac and connects.
- [ ] Menu bar icon and status text update when connected/disconnected.
- [ ] Slow drags produce precise pointer movement.
- [ ] Fast swipes remain smooth without large jumps.
- [ ] Host stop/start works from menu bar controls.
- [ ] iPhone app background/foreground recovers session correctly.
- [ ] Mac sleep/wake recovers hosting behavior.

## Unit tests to run in Xcode

- `ControlMessageTests.testMoveRoundTrip`
- `PointerScalingTests.testScalingNormalizesBySurfaceAndSensitivity`
