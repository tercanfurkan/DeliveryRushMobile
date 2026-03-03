# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Standard Xcode project, no package manager. Target iOS 18+. Signing via `Local.xcconfig` (gitignored) — copy from `Local.xcconfig.template`.

```bash
# Simulator
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
- `PersistenceManager.swift` — UserDefaults singleton: save/load/clearSave for progress; settings (isRightHanded, musicVolume) persist separately

## Feature Overview (current)

- **Cities (10)**: New York(L1)→Istanbul(L2)→Riyadh(L3)→Tokyo(L4)→London(L5)→Paris(L6)→Sao Paulo(L7)→Mumbai(L8)→Lagos(L9)→Sydney(L10)
- **Economy**: ScooterTier (basic/turbo/racing), GameTrack (8 tracks), ScooterColor (6 colors), 4 shop types per city
- **Missions**: food($50/50s), envelope($75/40s), mafia($200/65s + police). Timer counts from mission assignment.
- **Police**: chase on mafia pickup; also triggered by red light violations (8s cooldown, $10 fine)
- **Crash penalties**: traffic $35, building $10, caught by police $100
- **Throw**: `throwInFlight` flag prevents exploit; SFX: catMeow / glassCrash / "Hey!" (AVSpeechSynthesizer)
- **Traffic AI**: cars stop at red lights (`redLightStoppedVelocities` dict), resume on green
- **Pause/Save**: `pauseGame/resumeGame/saveAndExit` on `GameViewModel`; `hasSavedGame` drives "Continue" in main menu
- **Settings**: `isRightHanded` mirrors joystick/action layout; `musicVolume` slider; clear save

## Ways of Working (Agent Workflow)

When implementing significant features, follow this pattern:

### Parallel agent teams with worktrees
```bash
# Agents work in isolated git worktrees — no .pbxproj edits needed (PBXFileSystemSynchronizedRootGroup)
git worktree add .claude/worktrees/<name> -b <branch>
# After agents complete, merge sequentially (least to most conflicting)
git merge <branch> --no-ff
```

### QA gate — REQUIRED before declaring work done

The **orchestrator agent** (parent) MUST run all three checks after merging all worktrees. No task is complete until these pass cleanly:

```bash
# 1. Lint (warnings ok, errors must be zero)
make lint

# 2. Build — must succeed with zero errors
xcodebuild -project DeliveryRushMobile.xcodeproj \
  -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"

# 3. Tests — must pass
xcodebuild test -project DeliveryRushMobile.xcodeproj \
  -scheme DeliveryRushMobile \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \
  | grep -E "Test Suite|passed|failed"
```

Or with the Makefile shortcuts:
```bash
make lint && make build && make test
```

If any check fails: diagnose and fix before considering the task done. Do not skip or paper over failures with `--no-verify` or similar.

### Each agent's routine (atomic work)
1. Read relevant files before modifying anything
2. **Declare acceptance criteria** before writing any code (see below)
3. Implement the feature/fix
4. Spin up an Opus subagent to run `/simplify` on the changes
5. Verify acceptance criteria are met
6. Commit with a descriptive message

### Acceptance criteria (required for every implementation agent)

Every agent that is not the orchestrator or planner must explicitly state acceptance criteria at the start of their work and confirm each one before committing. Criteria must include at minimum:

- **≥60% automated test coverage** for the changed logic — write or update tests in `DeliveryRushMobileTests/DeliveryRushMobileTests.swift`; focus on `GameViewModel` and `GameModels` logic; use `make test` to verify
- **Manual test checklist** (if the change affects gameplay, UI, or audio) — list the specific in-game actions that must be verified, e.g. "tap THROW while package in flight → button stays disabled", "save & exit → continue → correct city and scooter restored"
- **No regressions** — existing tests must still pass after the change

Format to use at the start of each agent's work:
```
## Acceptance Criteria
- [ ] Tests: <what is being tested and target coverage>
- [ ] Manual: <specific actions to verify, or N/A>
- [ ] Regressions: all existing tests pass
```

### /simplify
Run `/simplify` (via `Skill` tool) after every significant body of changes. It reviews for:
- Unnecessary complexity / dead code
- Reuse opportunities
- Quality and efficiency issues

### TDD
- Write unit tests alongside feature code (target ~60% coverage)
- Focus tests on: `GameViewModel` economy/mission/shop logic, `GameModels` enums/structs
- Test file: `DeliveryRushMobileTests/DeliveryRushMobileTests.swift`
- Run via: `make test` (requires SwiftLint + xcodebuild)

### Static analysis
- SwiftLint config: `.swiftlint.yml` (game-tuned — long files/functions allowed)
- Run: `make lint` or `./scripts/lint.sh`
- Exits 0 if SwiftLint not installed (CI-safe)

### Merge conflict strategy
Order merges from least-to-most conflicting. Common conflict sites:
- `GameViewModel.swift`: keep ALL state vars + methods; never drop existing MARK sections
- `GamePlayView.swift`: preserve existing overlays + add new ones; preserve shop/levelup/pause
- `SoundManager.swift`: keep all music generators + add new cases
- `GameScene.swift` traffic removal block: preserve wider ±150 threshold + new dict cleanup

### Bundling
Bundle fixes + features together — no separate urgent bug fix PRs unless breaking.

