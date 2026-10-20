# Dauphin-iOS

[![.github/workflows/ci.yml](https://github.com/tkuitocc/dauphin-ios/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/tkuitocc/dauphin-ios/actions/workflows/ci.yml)

[![pages-build-deployment](https://github.com/tkuitocc/dauphin-ios/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/tkuitocc/dauphin-ios/actions/workflows/pages/pages-build-deployment)

[![Download on the App Store](https://github.com/user-attachments/assets/dd0f6bcb-6009-423e-a80b-b562ae3ee3b3)](https://apps.apple.com/tw/app/id6759800861)

[<img width="132" height="45" alt="Available on Apple TestFlight" src="docs/Available_on_TestFlight_badge.png" />](https://testflight.apple.com/join/D3K3B9pX)

## Overview

Dauphin is an iOS app with a companion Widget extension. The codebase is organized by feature and backed by XCTest coverage.

## Requirements

- Xcode 26.0 or newer
- iOS Simulator (iPhone 15 or newer recommended)
- Swift 5.9+

## Getting Started

1. Clone the repo.
2. Open `dauphin.xcodeproj` in Xcode.
3. Select the `dauphin` scheme and build/run.

### Xcode Cloud

Define `AES256KEY` and `AES256IV` as secret custom environment variables in the workflow. The post-clone script generates the ignored `dauphin/api.plist` from `dauphin/api.example.plist` before Xcode builds the app.

## Common Commands

```sh
xcodebuild -project dauphin.xcodeproj -scheme "dauphin" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' clean build
```

```sh
xcodebuild test -scheme dauphin -destination 'platform=iOS Simulator,name=iPhone 15'
```

```sh
swift-format lint --configuration .swift-format --recursive .
```

```sh
xcrun simctl install booted build/Debug-iphonesimulator/dauphin.app
```

## Project Structure

- `dauphin/`: iOS app sources (views, view models, utilities).
- `CoursesWidget/`: Widget extension.
- `Tests/`: Unit and snapshot tests.
- Root configs: `api.plist`, `StdID` (sample values only).

## Campus cameras

Open **Other → Campus Cameras** to view the ten [official Tamkang University webcams](https://webcam.ipcnet.tku.edu.tw/). Images refresh every 30 seconds while the page is active, with manual refresh and full-screen pinch zoom. Image timestamps are recognized on-device and shown in Taipei time; the server's file timestamp is labelled separately when recognition fails. A failed refresh preserves the previous image and its timestamp.

Camera strings are available in English and Traditional Chinese. Camera access does not require a university login.

Run camera UI tests separately from the default model tests:

```sh
xcodebuild -project app/dauphin.xcodeproj -scheme dauphin -testPlan Cameras \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -parallel-testing-enabled NO test
```

The camera UI tests use deterministic images only in Debug simulator builds. For camera-only local testing, copy `app/dauphin/api.example.plist` to the ignored `app/dauphin/api.plist`; actual course login still requires valid upstream API keys.

## Contributing

- Keep SwiftLint warnings at zero.
- Add or update tests for behavior changes.
- Run lint and tests before opening a PR.
