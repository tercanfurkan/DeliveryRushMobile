# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Standard Xcode project, no package manager. Target iOS 18+. Signing via `Local.xcconfig` (gitignored) — copy from `Local.xcconfig.template`. See README.md for full build and device install instructions.

**Quick reference (all use iPhone 16 Pro simulator):**
```bash
make build     # build for simulator
make test      # run unit tests
make lint      # SwiftLint — requires: brew install swiftlint
make coverage  # tests + coverage report
```

For physical device builds, see README.md § "Building and running from the command line".

## Architecture

SpriteKit game engine + SwiftUI overlay UI, MVVM pattern.

- **`GameScene.swift`** — all game logic: city generation, physics, traffic, police, missions, camera
- **`GameViewModel.swift`** — `@Observable` state bridge between scene and views; holds city locations, mission logic, score
- **`GameModels.swift`** — shared types: `MissionType`, `PhysicsCategory` bitmasks, `CityConfig` (10×10 grid, 70pt roads), `CityLocation`
- **`SoundManager.swift`** — all audio synthesized at runtime via AVAudioEngine (no asset files); music + SFX
- **`PersistenceManager.swift`** — UserDefaults singleton: save/load progress (level, money, upgrades); settings (isRightHanded, musicVolume) persist separately and are never cleared by clearSave()
- **`Views/`** — `GamePlayView` (HUD + SpriteView), `MinimapView` (Canvas), `JoystickView`, `MainMenuView`, `ShopView`

## Key Design Details

- City is a 10×10 block grid. `CityConfig.cellSize = blockSize(110) + roadWidth(70) = 180pt`
- Player physics: max speed 280, thrust 900, turn 5.5 rad/s; `PhysicsCategory` bitmasks gate all contacts
- Missions: food ($50/50s), envelope ($75/40s), mafia ($200/65s + police chase)
- Building textures are cached by seed (`[Int: SKTexture]`); traffic velocities stored in `[ObjectIdentifier: CGVector]`
- Pedestrians are driven by `SKAction` (no per-frame update); traffic lights updated via stored `[SKShapeNode]` arrays

## Feature Overview

- **Cities (10)**: New York(L1)→Istanbul(L2)→Riyadh(L3)→Tokyo(L4)→London(L5)→Paris(L6)→Sao Paulo(L7)→Mumbai(L8)→Lagos(L9)→Sydney(L10)
- **Economy**: ScooterTier (basic/turbo/racing), GameTrack (8 tracks), ScooterColor (6 colors), 4 shop types per city
- **Missions**: food/envelope/mafia; timer starts on assignment; time bonus on delivery
- **Police**: chase on mafia pickup + red light violations (8s cooldown, $10 fine)
- **Crash penalties**: traffic $35, building $10, caught by police $100; hard crash (speed>150) triggers police alert
- **Throw**: `throwInFlight` flag prevents exploit; window-throw SFX: catMeow / glassCrash / "Hey!" (AVSpeechSynthesizer)
- **Traffic AI**: cars stop at red lights (`redLightStoppedVelocities` dict), resume on green
- **Pause/Save**: `pauseGame/resumeGame/saveAndExit/giveUp` on `GameViewModel`; saves level, money, all owned/equipped upgrades
- **Settings**: `isRightHanded` mirrors joystick/action layout; `musicVolume` slider; clear save

## Ways of Working (Agent Workflow)

### QA gate — REQUIRED before declaring work done

The **orchestrator agent** MUST run all three checks after merging worktrees. No task is complete until these pass:

```bash
# Requires SwiftLint: brew install swiftlint
make lint && make build && make test
```

If `make lint` is blocked by a missing SwiftLint install, fix the install rather than skipping the check. If any check fails: diagnose and fix the root cause — do not bypass with `--no-verify` or similar.

### Parallel agent teams with worktrees

Use worktrees when multiple agents work on independent features simultaneously. Not needed for serial bugfixes.

```bash
git worktree add .claude/worktrees/<name> -b <branch>
# Merge sequentially after agents complete, least-to-most conflicting:
git merge <branch> --no-ff
```

### Merge conflict strategy

Merge in this order to minimise conflicts:

1. `GameModels.swift` — low conflict
2. `SoundManager.swift` — medium conflict
3. `GameViewModel.swift` — **keep ALL state vars and MARK sections; never drop existing ones**
4. `GameScene.swift` — preserve traffic removal block (±150 threshold) + dict cleanup
5. `GamePlayView.swift` — preserve all overlays (shop/levelup/pause); add new ones after

### Each agent's routine (atomic work)

1. Read relevant files before modifying anything
2. **Declare acceptance criteria** before writing any code (see below)
3. Implement the feature/fix
4. Run `/simplify` via the `Skill` tool on the changed code
5. Verify acceptance criteria are met
6. Commit with a descriptive message

### Acceptance criteria (every implementation agent — not orchestrator/planner)

Declare these at the start of work and confirm each before committing:

```
## Acceptance Criteria
- [ ] Tests: <specific logic covered, e.g. "GameViewModel.deliverPackage reward calc"> — run `make test`
- [ ] Manual: <specific in-game actions to verify, e.g. "save & exit → continue → correct city restored"> — or N/A
- [ ] Regressions: run `make test` before and after; all previously passing tests still pass
```

**Testing standard:** ≥60% coverage for changed logic. Test file: `DeliveryRushMobileTests/DeliveryRushMobileTests.swift`. Focus on `GameViewModel` (economy, missions, shop, level) and `GameModels` (enums, structs). SpriteKit integration code that cannot be unit tested must be covered by the manual checklist instead.

### /simplify

Run `/simplify` (via `Skill` tool) after every significant body of changes. It reviews for unnecessary complexity, dead code, reuse opportunities, and efficiency issues.

### Static analysis

- SwiftLint config: `.swiftlint.yml` (game-tuned — long files/functions allowed)
- Run: `make lint` — requires `brew install swiftlint`; exits 1 if not installed

### Bundling

Combine bug fixes and related features in the same PR to avoid churn. Exception: crashes, data loss, or security issues may be fast-tracked as standalone fixes.
