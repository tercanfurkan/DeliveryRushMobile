# DeliveryRushMobile — Feature Specs v2

> Supersedes earlier spec. All changes target iOS 18+, SpriteKit + SwiftUI, no external dependencies.
> Five parallel feature streams (A–E).

---

## Stream A — Bug Fixes

### A1 · Throw Exploit Fix
**File:** `GameScene.swift` → `updateThrowProximity()` (~line 970)

**Bug:** Clicking THROW multiple times while `canThrow = true` queues multiple
`throwPackage()` calls during the 0.5 s flight animation; each awards full
mission money on landing.

**Fix:** Set `vm.canThrow = false` immediately inside the guard block, before
calling `throwPackage()`:
```swift
if vm.throwRequested && vm.canThrow {
    vm.throwRequested = false
    vm.canThrow = false          // ← prevent re-queuing during flight
    throwPackage(to: mission.delivery.worldPosition)
}
```

---

### A2 · Car Corner Stacking Fix
**File:** `GameScene.swift` → `createTrafficVehicle()` and `updateTraffic()`

**Bug:** Traffic vehicles have `PhysicsCategory.boundary` in their
`collisionBitMask`, so they bounce off the world edge and pile up at corners.

**Fix:**
1. Remove `PhysicsCategory.boundary` from traffic `collisionBitMask`.
2. Widen removal threshold in `updateTraffic()` from ±60 to ±150 so cars are
   despawned before they visually cluster.

---

### A3 · Player World-Edge Wrapping
**File:** `GameScene.swift` → `updatePlayer()`, `setupWorldBoundary()`

**Goal:** Player scooter wraps to the opposite edge when it exits the world
(Pac-Man style), preserving velocity and angle.

**Implementation:**
- Remove (or make player-excluded) `setupWorldBoundary()` edge-loop so the
  player is no longer blocked by physics at edges.
- After physics update in `updatePlayer()`:
  ```swift
  let ws = CityConfig.worldSize + CityConfig.roadWidth
  if playerNode.position.x < 0    { playerNode.position.x = ws }
  if playerNode.position.x > ws   { playerNode.position.x = 0  }
  if playerNode.position.y < 0    { playerNode.position.y = ws }
  if playerNode.position.y > ws   { playerNode.position.y = 0  }
  ```
- Snap camera position after warp to avoid visible jump.

---

## Stream B — Shop System

### B1 · Shop Data Model
**File:** `GameModels.swift`

```swift
nonisolated enum ShopType: CaseIterable, Sendable {
    case scooterStore, musicStore, paintStore, portalStore
    var name: String  // "Moto Shop", "Beat Store", "Paint & Ride", "Portal Hub"
    var emoji: String // 🛵, 🎵, 🎨, 🌀
    var signColor: UIColor
}

nonisolated struct Shop: Sendable {
    let type: ShopType
    let gridX: Int
    let gridY: Int
    var worldPosition: CGPoint { /* same formula as CityLocation */ }
}
```

Also add `static let shop: UInt32 = 1 << 8` to `PhysicsCategory`.

---

### B2 · Shop Placement & Scene Visuals
**Files:** `GameViewModel.swift`, `GameScene.swift`

**Placement:** Generate 4 shops at game start (one per quadrant: top-left,
top-right, bottom-left, bottom-right). Within each quadrant (0–4 or 5–9 grid
range), randomise the cell. Never overlap a `CityLocation`.

**Visual:** Draw each shop in `buildCity()` as a special building:
- Distinct sign `SKLabelNode` (emoji + name), zPosition 12.
- Pulsing proximity ring: `SKShapeNode(circleOfRadius: 55)` with dashed stroke,
  color matching `ShopType.signColor`, repeating opacity pulse.

---

### B3 · Shop Proximity Detection & HUD Button
**Files:** `GameViewModel.swift`, `GameScene.swift`, `GamePlayView.swift`

- `GameViewModel`: add `var nearbyShop: Shop? = nil`, `var isShopOpen = false`.
- In `GameScene.update()`, call `updateShopProximity()` which checks distance
  from player to each shop; set `vm.nearbyShop` when dist < 70 pt.
- `GamePlayView.controlsBar`: show "ENTER SHOP" button (same pill style as
  THROW) when `nearbyShop != nil && !isShopOpen`. Tapping sets
  `viewModel.isShopOpen = true`.

---

### B4 · Shop Overlay UI
**New file:** `DeliveryRushMobile/Views/ShopView.swift`

Full-screen sheet presented over `GamePlayView` when `isShopOpen = true`.

```
╔══════════════════════════╗
║  🛵  Moto Shop      ✕    ║
╠══════════════════════════╣
║  [Item]  [Item]          ║
║  [Item]  [Item]          ║
╠══════════════════════════╣
║  Wallet: $420            ║
╚══════════════════════════╝
```

- Grid of `ShopItemCard` views (name, description, price, BUY button).
- BUY disabled if `money < price` or already owned.
- On purchase: `viewModel.purchaseItem(...)` deducts money, records ownership.

---

### B5 · Scooter Store
**Files:** `GameModels.swift`, `GameViewModel.swift`, `GameScene.swift`

```swift
nonisolated enum ScooterTier: Int, CaseIterable, Sendable {
    case basic = 0, turbo = 1, racing = 2
    var displayName: String  // "Basic Scooter", "Turbo Scooter", "Racing Scooter"
    var price: Int           // 0, 200, 500
    var maxSpeed: CGFloat    // 280, 340, 400
    var thrust: CGFloat      // 900, 1100, 1300
    var turnSpeed: CGFloat   // 5.5, 5.5, 6.5
}
```

`GameViewModel`: `var equippedScooter: ScooterTier = .basic`,
`var ownedScooters: Set<ScooterTier> = [.basic]`.

`GameScene.setupPlayer()`: read `viewModel?.equippedScooter` to set physics
constants. Turbo = orange-red body, Racing = silver body.

---

### B6 · Music Store
**Files:** `GameModels.swift`, `GameViewModel.swift`, `SoundManager.swift`

```swift
nonisolated enum MusicTrack: CaseIterable, Sendable {
    case original, jazz, electronic, lofi
    var displayName: String  // "City Rush", "Smooth Jazz", "Neon Electronic", "Chill Lo-Fi"
    var price: Int           // 0, 150, 150, 100
    var bpm: Double          // 135, 90, 140, 75
    var character: String    // description shown in store
}
```

`SoundManager`: add `func switchTrack(_ track: MusicTrack)` — rebuild
oscillator/filter graph with appropriate BPM and waveform mix (jazz = softer
sine chords; electronic = square lead; lofi = muffled noise + slow beats).

`GameViewModel`: `var activeTrack: MusicTrack = .original`,
`var ownedTracks: Set<MusicTrack> = [.original]`.

---

### B7 · Paint Store
**Files:** `GameModels.swift`, `GameViewModel.swift`, `GameScene.swift`

```swift
nonisolated enum ScooterColor: CaseIterable, Sendable {
    case yellow, red, blue, green, purple, gold
    var displayName: String
    var price: Int        // yellow = 0, others = 75
    var bodyColor: UIColor
    var strokeColor: UIColor
}
```

`GameViewModel`: `var scooterColor: ScooterColor = .yellow`,
`var ownedColors: Set<ScooterColor> = [.yellow]`.
`GameScene.setupPlayer()`: apply `viewModel?.scooterColor.bodyColor`.

---

### B8 · Portal Store
**Files:** `GameViewModel.swift`, `ShopView.swift`

Item: "Travel to [nextCityName] — $100".
Enabled only when `deliveriesThisLevel >= 8` (near level threshold).
On purchase: call `viewModel.advanceLevel()`.
If already max city, show "You've seen it all! 🌍" (disabled item).

---

## Stream C — Level & City System

### C1 · Level Progression
**File:** `GameViewModel.swift`

- Add `var currentLevel: Int = 1`, `var deliveriesThisLevel: Int = 0`,
  `var pendingLevelTransition = false`.
- In `deliverPackage()`: increment both counters; when
  `deliveriesThisLevel >= 10`, call `advanceLevel()`.
- `advanceLevel()`:
  1. `currentLevel += 1`, `deliveriesThisLevel = 0`.
  2. `pendingLevelTransition = true` (shows overlay).
  3. After 3 s delay: rebuild `GameScene` with new theme, call
     `soundManager.switchTrack(theme.musicTrack)`.
- Reset `pendingLevelTransition = false` after rebuild.

---

### C2 · City Theme Model
**File:** `GameModels.swift`

```swift
nonisolated struct CityTheme: Sendable {
    let name: String
    let level: Int
    let roadColor: UIColor
    let sidewalkColor: UIColor
    let buildingColors: [UIColor]
    let backgroundColor: UIColor
    let trafficAccentColor: UIColor   // dominant car/taxi color
    let skylineEmoji: String          // landmark 🗽 / 🕌 / 🕋
    let musicTrack: MusicTrack
}

extension CityTheme {
    // New York: dark asphalt, grey steel, yellow taxis
    static let newYork = CityTheme(name: "New York", level: 1,
        roadColor: UIColor(red:0.20,green:0.20,blue:0.22,alpha:1),
        sidewalkColor: UIColor(red:0.38,green:0.37,blue:0.36,alpha:1),
        buildingColors: [/* steel-grey, red brick, beige limestone, dark glass */],
        backgroundColor: UIColor(red:0.15,green:0.15,blue:0.17,alpha:1),
        trafficAccentColor: UIColor(red:1.0,green:0.82,blue:0.1,alpha:1),
        skylineEmoji: "🗽", musicTrack: .original)

    // Istanbul: warm stone, ochre buildings, red trams
    static let istanbul = CityTheme(name: "Istanbul", level: 2,
        roadColor: UIColor(red:0.25,green:0.22,blue:0.18,alpha:1),
        sidewalkColor: UIColor(red:0.52,green:0.46,blue:0.38,alpha:1),
        buildingColors: [/* warm ochre, terracotta, cream, dusty rose */],
        backgroundColor: UIColor(red:0.22,green:0.18,blue:0.14,alpha:1),
        trafficAccentColor: UIColor(red:0.85,green:0.15,blue:0.15,alpha:1),
        skylineEmoji: "🕌", musicTrack: .jazz)

    // Riyadh: sandy desert, white modern towers, beige roads
    static let riyadh = CityTheme(name: "Riyadh", level: 3,
        roadColor: UIColor(red:0.55,green:0.50,blue:0.40,alpha:1),
        sidewalkColor: UIColor(red:0.72,green:0.66,blue:0.54,alpha:1),
        buildingColors: [/* white marble, sand, light concrete, pale gold */],
        backgroundColor: UIColor(red:0.60,green:0.55,blue:0.42,alpha:1),
        trafficAccentColor: UIColor(red:0.95,green:0.95,blue:0.95,alpha:1),
        skylineEmoji: "🕋", musicTrack: .electronic)

    static func theme(for level: Int) -> CityTheme {
        switch level { case 2: return .istanbul; case 3: return .riyadh; default: return .newYork }
    }
}
```

---

### C3 · Apply Theme in Scene
**File:** `GameScene.swift`

- Add `var cityTheme: CityTheme = .newYork`.
- Replace all hardcoded colour literals in `buildCity()`, `setupPlayer()`,
  `createTrafficVehicle()`, and background colour with `cityTheme.*`.
- `GameViewModel.startGame()` (and `advanceLevel()`) must set
  `scene.cityTheme = CityTheme.theme(for: currentLevel)` before calling any
  build methods.

---

### C4 · Level-Up Transition Overlay
**New file:** `DeliveryRushMobile/Views/LevelUpView.swift`

Shown when `viewModel.pendingLevelTransition = true`.

```
LEVEL 2
🕌
Welcome to Istanbul
[animated progress dots]
```

- Slide-up entrance animation, 3 s hold, then fade out.
- On dismiss: `viewModel.completeLevelTransition()` rebuilds the scene.

---

### C5 · City Name HUD Badge
**File:** `GamePlayView.swift`

Add a small pill badge in `hudRight` (below delivery counter):
`"🗽 New York"` → `"🕌 Istanbul"` → `"🕋 Riyadh"`.
Driven by `viewModel.currentTheme.skylineEmoji + " " + viewModel.currentTheme.name`.
Add `var currentTheme: CityTheme` to `GameViewModel`, set from `startGame()`.

---

## Stream D — Police Improvements

### D1 · Police Chase Warning HUD
**Files:** `GameViewModel.swift`, `GameScene.swift`, `GamePlayView.swift`

- `GameViewModel`: add `var policeChaseDistance: CGFloat = .infinity`.
- `GameScene.updatePolice()`: after computing `dx/dy`, also update
  `vm.policeChaseDistance = min(current, dist_to_closest_cop)`. Reset to
  `.infinity` when `policeNode.children.isEmpty`.
- `GamePlayView`: add a dedicated police alert banner (separate from
  `missionBanner`):
  - `policeChaseDistance < 250` → yellow "🚨 Police nearby — lose them!" (pulse).
  - `policeChaseDistance < 80`  → red "🚨 PULL OVER NOW!" (fast pulse + shake).
  - Hidden when no police or distance is large.

---

### D2 · Caught → Respawn at Police Station
**Files:** `GameModels.swift`, `GameViewModel.swift`, `GameScene.swift`

- `CityTheme` gains `policeStationGrid: (Int, Int)` (e.g. NY=(1,1), IST=(2,2),
  RYD=(1,2)).
- Computed `policeStationPosition` world coords in theme or GameScene helper.
- `GameScene`: add `func respawnAtPoliceStation()`:
  - Teleport `playerNode.position` to station coords.
  - Zero player velocity.
  - Brief white flash overlay.
- `GameViewModel.caughtByPolice()`: call `gameScene?.respawnAtPoliceStation()`.
  Update message: `"🚔 Busted! Taken to the police station."`.

---

## Stream E — Throw Package Improvements

### E1 · Random Window Placement
**File:** `GameScene.swift`

- Add `private var deliveryWindowOffset: CGFloat = 25`.
- In `showDeliveryMarker()`, set
  `deliveryWindowOffset = CGFloat.random(in: 10...55)` and use this offset for
  the `windowGlow` Y position instead of the hardcoded `+25`.
- In `throwPackage(to target:)`, compute
  `windowTarget = CGPoint(x: target.x, y: target.y + deliveryWindowOffset)`
  instead of `target.y + 25`.

---

### E2 · Post-Throw Impact Effects
**File:** `GameScene.swift` → extend `showDeliveryEffect(at:)`

Pick one of three effects at random (`Int.random(in: 0...2)`), run _after_ the
existing particle burst:

**Effect 0 — Broken Window:**
```
Glass shard particles (8–12 white/grey thin rects), radiate outward 15–40 pt,
fade in 0.4 s.
Window glow flashes white (0.05 s) then fades dark.
```

**Effect 1 — Frightened Cat:**
```
SKLabelNode("😺") at windowTarget, fontSize 22.
Animate: scale 1→1.6 + moveBy(0,12) over 0.3 s, then fade out 0.5 s.
Optional: "Meow!" SKLabelNode fades up 10 pt and disappears in 0.8 s.
```

**Effect 2 — Angry Person:**
```
SKLabelNode("😡") at windowTarget, fontSize 22.
Animate: bounce up 8 pt (0.15 s ease-out), hold 0.3 s, fade out 0.4 s.
Optional: "Hey!!" SKLabelNode arcs up and fades in 0.7 s.
```

All effects zPosition ≥ 25 so they render above buildings.

---

## Implementation Notes

- **`@Observable` pattern:** All new `GameViewModel` properties are plain `var`.
  No `@Published`.
- **No new packages/assets.** Audio synthesised in `SoundManager` only.
- **Shop inventory persists** across level transitions (only `GameScene` is
  rebuilt, not `GameViewModel`).
- **World wrapping (A3)** requires removing the player from the boundary
  collision mask (`playerNode.physicsBody?.collisionBitMask` must not include
  `PhysicsCategory.boundary`), or deleting the edge-loop body altogether.
- **`PhysicsCategory.shop = 1 << 8`** — add this before any other changes that
  touch bitmasks.
- **Worktree strategy:** Streams A, D, E are small (1–3 files each). Streams B
  and C are larger and each add new Swift files. Merge order: A → D/E → B → C
  to minimise conflicts on `GameScene.swift`.
