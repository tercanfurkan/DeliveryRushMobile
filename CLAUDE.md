# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a standard Xcode project — no Makefile or package manager.

```bash
# Build
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile -configuration Debug build

# Run tests
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile test

# Run on specific simulator
xcodebuild -project DeliveryRushMobile.xcodeproj -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

From Xcode: `Cmd+B` (build), `Cmd+R` (run), `Cmd+U` (test).

## Architecture

**DeliveryRushMobile** is a SpriteKit-based iOS game with a SwiftUI overlay UI. It follows an MVVM-like structure, though `GameViewModel` is currently empty.

### Layer overview

| Layer | Files | Responsibility |
|-------|-------|----------------|
| SwiftUI Views | `Views/` | HUD, menus, joystick, minimap |
| Game Engine | `Game/GameScene.swift` | All SpriteKit physics and game logic |
| Models | `Models/GameModels.swift` | Enums and structs shared across layers |
| Services | `Services/SoundManager.swift` | Procedural audio synthesis via AVAudioEngine |
| ViewModel | `ViewModels/GameViewModel.swift` | **Currently empty** — game state bridge |

### Key files

- **`GameScene.swift`** (~1,147 lines) — the core game. Handles city generation, player physics, traffic/pedestrian spawning, police behavior, collision detection, mission markers, and camera. Player max speed is 280 units/s, thrust force 900, turn speed 5.5 rad/s.
- **`GameModels.swift`** — defines `MissionType` (food/envelope/mafia), `GamePhase`, `LocationType`, `PhysicsCategory` bitmasks, `CityConfig` (10×10 grid), and `SoundEffect`.
- **`GamePlayView.swift`** — embeds `SpriteView(scene:)` and overlays the HUD, mission banner, joystick, crash flash, delivery popup, and game over screen.
- **`SoundManager.swift`** — generates all audio at runtime (no audio asset files). Produces 135 BPM background music and synthesized SFX (pickup chord, delivery arpeggio, crash noise, police siren) using sine/square/triangle/noise waveforms via AVAudioEngine.
- **`MinimapView.swift`** — Canvas-based mini-map that scales world coordinates to show roads, buildings, player (yellow), pickup (green), and delivery target (orange).
- **`JoystickView.swift`** — drag-based virtual joystick that returns a normalized `CGVector` direction to `GameScene`.

### Mission system

- **Food delivery** — 50 pts, 50 s timer
- **Express envelope** — 75 pts, 40 s timer
- **Suspicious package (mafia)** — 200 pts, 65 s timer, police spawned

### Physics

All collision detection uses `PhysicsCategory` bitmasks defined in `GameModels.swift`. A crash triggers the red-flash overlay in `GamePlayView` and ends the game.

## Frameworks

No external dependencies — only Apple frameworks: SwiftUI, SpriteKit, AVFoundation, CoreGraphics, Foundation.
