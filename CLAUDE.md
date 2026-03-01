# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Standard Xcode project, no package manager. Available simulators: iPhone 17 Pro (iOS 26.2), target iOS 18+.

```bash
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install & launch on booted simulator (id: 354EA372-3DC4-4D98-9038-7BF2C83A2BA5)
xcrun simctl install booted <app-path> && xcrun simctl launch booted app.rork.delivery-rush-mobile
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
