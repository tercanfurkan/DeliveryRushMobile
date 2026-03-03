# Delivery Rush Mobile

A top-down 2D arcade mobile game where you play as a delivery courier racing through a miniature animated city. Complete deliveries, avoid crashes, and survive as long as possible.

Built with Swift, SwiftUI, and SpriteKit. No external dependencies — Apple frameworks only.

## Requirements

- Xcode 16+
- iOS 18+ device or simulator
- Apple Developer account (free tier works for device installs)

## Getting Started

### 1. Clone

```bash
git clone https://github.com/tercanfurkan/DeliveryRushMobile.git
cd DeliveryRushMobile
```

### 2. Configure signing

```bash
cp Local.xcconfig.template Local.xcconfig
```

Edit `Local.xcconfig` and replace `YOUR_TEAM_ID` with your Apple Developer Team ID.
Find yours in [Xcode → Settings → Accounts](https://developer.apple.com/account) or at developer.apple.com.

### 3. Install the pre-commit hook

```bash
git config core.hooksPath .githooks
```

This blocks accidental commits of team IDs, device UDIDs, and other sensitive identifiers.

### 4. Open in Xcode

```bash
open DeliveryRushMobile.xcodeproj
```

Select your target device in the toolbar and press **⌘R** to build and run.

## Build, Test & Static Analysis

A `Makefile` covers all common tasks. The default simulator target is **iPhone 16 Pro**.

```bash
make build     # Build for simulator
make test      # Run unit tests
make coverage  # Run tests with code coverage report
make lint      # Run SwiftLint (requires installation — see below)
make lint-fix  # Auto-fix SwiftLint violations
make open      # Open the project in Xcode
make clean     # Clean derived data
make help      # List all targets
```

SwiftLint (optional but recommended — `make lint` will fail if not installed):
```bash
brew install swiftlint
```

### Building and running from the command line

```bash
# Simulator — build and launch
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO build
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "DeliveryRushMobile.app" | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.nollayks.deliveryrush

# Physical device — find your UDID with: xcrun devicectl list devices
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS,id=<DEVICE_UDID>' -configuration Debug build
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "DeliveryRushMobile.app" | head -1)
xcrun devicectl device install app --device <DEVICE_UDID> "$APP"
xcrun devicectl device process launch --device <DEVICE_UDID> com.nollayks.deliveryrush
```

Note: `make build` and `make test` use `xcpretty` for formatted output if installed (`brew install xcpretty`), and fall back to raw xcodebuild output otherwise.

## Architecture

| File | Responsibility |
|------|---------------|
| `Game/GameScene.swift` | All game logic: city generation, physics, traffic, police, missions, camera |
| `ViewModels/GameViewModel.swift` | `@Observable` state bridge between SpriteKit scene and SwiftUI views |
| `Models/GameModels.swift` | Shared types: `MissionType`, `PhysicsCategory`, `CityConfig`, `CityLocation` |
| `Services/SoundManager.swift` | Procedural audio via AVAudioEngine — music + SFX, no asset files |
| `Services/PersistenceManager.swift` | UserDefaults save/load for game progress and settings |
| `Views/` | `GamePlayView`, `MinimapView`, `JoystickView`, `MainMenuView`, `ShopView` |

## Sensitive Data Policy

`Local.xcconfig` is gitignored and must never be committed. The pre-commit hook (`.githooks/pre-commit`) will block commits containing:

- Apple Developer Team IDs
- Device UDIDs
- Provisioning profile UUIDs
- API keys / secrets / tokens

To bypass in an emergency: `git commit --no-verify`

## License

Copyright © 2026 Nollayks. All rights reserved.
