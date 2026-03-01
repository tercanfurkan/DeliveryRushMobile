# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Standard Xcode project, no package manager. Target iOS 18+. Signing via `Local.xcconfig` (gitignored) — copy from `Local.xcconfig.template`.

```bash
# Simulator (iPhone 17 Pro, id: 354EA372-3DC4-4D98-9038-7BF2C83A2BA5)
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcrun simctl install booted <app-path> && xcrun simctl launch booted com.nollayks.deliveryrush

# Physical device — get UDID via: xcrun devicectl list devices
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS,id=<DEVICE_UDID>' -configuration Debug build
xcrun devicectl device install app --device <DEVICE_UDID> <app-path>
xcrun devicectl device process launch --device <DEVICE_UDID> com.nollayks.deliveryrush
```

## Architecture

SpriteKit game engine + SwiftUI overlay UI, MVVM pattern.

- **`GameScene.swift`** — all game logic: city generation, physics, traffic, police, missions, camera
- **`GameViewModel.swift`** — `@Observable` state bridge between scene and views; holds city locations, mission logic, score
- **`GameModels.swift`** — shared types: `MissionType`, `PhysicsCategory` bitmasks, `CityConfig` (10×10 grid, 70pt roads), `CityLocation`
- **`SoundManager.swift`** — all audio synthesized at runtime via AVAudioEngine (no asset files); 135 BPM music + SFX
- **`Views/`** — `GamePlayView` (HUD + SpriteView), `MinimapView` (Canvas), `JoystickView`, `MainMenuView`

## Key design details

- City is a 10×10 block grid. `CityConfig.cellSize = blockSize(110) + roadWidth(70) = 180pt`
- Player physics: max speed 280, thrust 900, turn 5.5 rad/s; `PhysicsCategory` bitmasks gate all contacts
- Missions: food ($50/50s), envelope ($75/40s), mafia ($200/65s + police chase)
- Building textures are cached by seed (`[Int: SKTexture]`); traffic velocities stored in `[ObjectIdentifier: CGVector]`
- Pedestrians are driven by `SKAction` (no per-frame update); traffic lights updated via stored `[SKShapeNode]` arrays
