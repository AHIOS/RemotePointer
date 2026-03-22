# Contributing

Thanks for contributing to RemotePointer.

## Branching Strategy

This project uses a lightweight trunk-based workflow:

- `main` is always releasable.
- Create short-lived feature branches from `main`.
- Merge with a Pull Request.
- Delete feature branches after merge.

Branch name examples:

- `feature/keyboard-input`
- `feature/scroll-gestures`
- `fix/connection-retry`
- `chore/readme-update`

## Commit Style

Use small, focused commits with clear intent:

- `feat: add keyboard text input channel`
- `fix: improve reconnect handling on iPhone`
- `docs: update setup and permissions section`

## Pull Request Checklist

- [ ] Builds succeed for both `RemotePointeriOS` and `RemotePointerMac`
- [ ] No obvious regressions in pointer movement/click behavior
- [ ] README/docs updated if behavior or setup changed
- [ ] Scope is focused (one feature/fix per PR)

## Local Build Commands

From repository root:

- `xcodegen generate`
- `xcodebuild -project "RemotePointer.xcodeproj" -scheme "RemotePointerMac" -configuration Debug -destination "platform=macOS" build`
- `xcodebuild -project "RemotePointer.xcodeproj" -scheme "RemotePointeriOS" -configuration Debug -destination "generic/platform=iOS" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build`
