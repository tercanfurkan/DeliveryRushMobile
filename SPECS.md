# Delivery Rush — Game Specification

## Concept

A top-down 2D arcade mobile game where the player is a delivery courier. The player earns money by completing package deliveries across a miniature animated city. Speed matters, but crashes cost money. The tone is energetic and arcade-y with a stylized-but-real-looking aesthetic.

## Core Loop

1. A **pickup marker** appears on the map (green, pulsing)
2. Player drives to the pickup zone — package auto-attaches on contact (no button needed)
3. A **delivery marker** appears (orange) + a glowing window on the target building
4. Player races to the destination
5. When close enough, a **THROW** button appears — player tosses the package through the window
6. Package flies in with a particle burst → money earned
7. Next mission immediately spawns — keep delivering to survive

## Mission Types

| Type | Icon | Reward | Timer | Special |
|------|------|--------|-------|---------|
| Food Delivery | 🍕 🍔 🍣 🌮 🍜 ☕ | $50 | 50s | None |
| Express Envelope | 📦 | $75 | 40s | None |
| Suspicious Package (mafia) | 🔒 | $200 | 65s | Police chase spawns |

- Food pickup icons must match the specific restaurant (🍕 Pizza Palace, 🍔 Burger Joint, 🍣 Sushi Express, 🌮 Taco Stand, 🍜 Noodle House, ☕ Coffee Corner)
- Delivery destination icons: 🏠 houses, 🏢 offices, 📦 warehouses
- Mission banner always shows the correct icon for the active mission

## Economy & Game Over

- Start with a money balance
- **Money lost on crash:** $15 (NPC traffic), $5 (building collision)
- **Busted by police:** $50 penalty
- **Mission failed (timer out):** no reward
- **Game over:** when balance hits $0

## Player & Controls

- **Vehicle:** yellow delivery scooter with a visible package on-board after pickup
- **Joystick (bottom-left):** point in direction to steer and accelerate — normalized CGVector input
- **THROW button:** context-sensitive, appears only when near the delivery point
- Physics-based movement: max speed 280 units/s, thrust force 900, turn speed 5.5 rad/s
- Crash flash (red overlay) + haptic feedback on collision

## City Layout

- **10×10 grid** of city blocks with roads between them
- **Road widths:** main roads are wide (~70pt), secondary/thin roads also exist
- **Sidewalks** with curbs on both sides of every road
- **Crosswalks** at intersections
- **Buildings:** varied architecture with lit/unlit windows, rooftop details, drop shadows
- **Parks:** walking paths, benches, trees
- **Sidewalk trees** along streets
- Aesthetic: stylized/animatic but grounded — miniature city look, not abstract

### Location Types

- Restaurant (multiple, with distinct food identities)
- Office
- House
- Warehouse
- Park

### Pickup/Delivery Marker Placement

- Markers are placed **on the road in front of buildings** (south side), not at building centers
- This allows the player to drive up without hitting the building
- Window glow appears on the building itself for the throw animation

## Traffic & Pedestrians

- **NPC vehicles:** up to 22 on the map at once, including occasional trucks; have tail lights
- **Pedestrians:** up to 18 walking on sidewalks at once
- **Traffic lights:** at intersections, cycle green/red every 6 seconds
- Crashing into traffic costs the player $15

## Police (Mafia Missions Only)

- Police units spawn and chase the player during Suspicious Package missions
- Flashing red/blue lights on police vehicles
- Getting caught = "Busted" state + $50 penalty

## Camera

- Smooth follow camera with lag (does not snap instantly to player)

## Minimap

- Displayed in the **top-right corner**
- Shows full city grid: roads and buildings
- **Yellow dot** = player position
- **Green dot** = pickup location
- **Orange dot** = delivery location
- Canvas-rendered, updates in real-time

## HUD Elements

- Current money balance
- Active mission timer
- Delivery count
- Mission banner with icon + police alert when applicable
- Minimap (top-right)
- Joystick (bottom-left)
- THROW button (context-sensitive)

## Audio

All audio is **procedurally generated** via AVAudioEngine — no bundled audio files.

### Background Music
- Energetic chiptune loop at **135 BPM**
- Layers: bass, melody, percussion
- Loops continuously during gameplay

### Sound Effects

| Event | Effect |
|-------|--------|
| Package pickup | Chime / pickup chord |
| Delivery complete | Fanfare / arpeggio |
| Crash | Noise burst |
| Police nearby | Siren (looping while police active) |

### Waveforms Used
- Sine, square, triangle, noise
- Separate volume channels: music (~0.18), SFX (~0.45)

## Visual Polish

- Animated pulsing mission markers (pickup and delivery)
- Particle burst on successful delivery
- Crash flash: brief red screen tint
- Glowing window highlight at delivery target
- Animated main menu with staggered entrance, gradient title "DELIVERY RUSH", bouncing 🛵 emoji
- High score shown on main menu

## Technical Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Game engine:** SpriteKit (physics, scene, sprites)
- **Audio:** AVFoundation / AVAudioEngine
- **Minimap:** SwiftUI Canvas
- **No external dependencies** — Apple frameworks only
