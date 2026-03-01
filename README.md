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

## Building from the Command Line

```bash
# Simulator
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Physical device — find your UDID with: xcrun devicectl list devices
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS,id=<DEVICE_UDID>' -configuration Debug build

xcrun devicectl device install app --device <DEVICE_UDID> \
  <path-to-DeliveryRushMobile.app>
xcrun devicectl device process launch --device <DEVICE_UDID> \
  com.nollayks.deliveryrush
```

## Architecture

| File | Responsibility |
|------|---------------|
| `Game/GameScene.swift` | All game logic: city generation, physics, traffic, police, missions, camera |
| `ViewModels/GameViewModel.swift` | `@Observable` state bridge between SpriteKit scene and SwiftUI views |
| `Game/GameModels.swift` | Shared types: `MissionType`, `PhysicsCategory`, `CityConfig`, `CityLocation` |
| `Services/SoundManager.swift` | Procedural audio via AVAudioEngine — 135 BPM music + SFX, no asset files |
| `Views/` | `GamePlayView`, `MinimapView`, `JoystickView`, `MainMenuView` |

## Sensitive Data Policy

`Local.xcconfig` is gitignored and must never be committed. The pre-commit hook (`.githooks/pre-commit`) will block commits containing:

- Apple Developer Team IDs
- Device UDIDs
- Provisioning profile UUIDs
- API keys / secrets / tokens

To bypass in an emergency: `git commit --no-verify`

## License

Copyright © 2026 Nollayks. All rights reserved.
