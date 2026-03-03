import Foundation
import CoreGraphics
import UIKit

nonisolated enum MissionType: CaseIterable, Sendable {
    case food
    case envelope
    case mafia

    var title: String {
        switch self {
        case .food: "Food Delivery"
        case .envelope: "Express Envelope"
        case .mafia: "Suspicious Package"
        }
    }

    var emoji: String {
        switch self {
        case .food: "🍽️"
        case .envelope: "✉️"
        case .mafia: "📦"
        }
    }

    var reward: Int {
        switch self {
        case .food: 50
        case .envelope: 75
        case .mafia: 200
        }
    }

    var timeLimit: TimeInterval {
        switch self {
        case .food: 50
        case .envelope: 40
        case .mafia: 65
        }
    }

    var hasPolice: Bool {
        self == .mafia
    }
}

nonisolated struct PhysicsCategory: Sendable {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let building: UInt32 = 1 << 1
    static let traffic: UInt32 = 1 << 2
    static let police: UInt32 = 1 << 3
    static let pickup: UInt32 = 1 << 4
    static let delivery: UInt32 = 1 << 5
    static let boundary: UInt32 = 1 << 6
    static let pedestrian: UInt32 = 1 << 7
    static let shop: UInt32 = 1 << 8
}

nonisolated struct CityConfig: Sendable {
    static let gridSize = 10
    static let blockSize: CGFloat = 110
    static let roadWidth: CGFloat = 70
    static let cellSize: CGFloat = blockSize + roadWidth
    static let worldSize: CGFloat = CGFloat(gridSize) * cellSize
    static let sidewalkWidth: CGFloat = 7
}

nonisolated enum LocationType: Sendable {
    case restaurant
    case office
    case house
    case warehouse
    case park
}

nonisolated struct CityLocation: Sendable {
    let name: String
    let gridX: Int
    let gridY: Int
    let type: LocationType

    var worldPosition: CGPoint {
        let x = CGFloat(gridX) * CityConfig.cellSize + CityConfig.roadWidth + CityConfig.blockSize / 2
        let y = CGFloat(gridY) * CityConfig.cellSize + CityConfig.roadWidth + CityConfig.blockSize / 2
        return CGPoint(x: x, y: y)
    }

    var markerPosition: CGPoint {
        let center = worldPosition
        let offset = CityConfig.blockSize / 2 + CityConfig.roadWidth / 2
        return CGPoint(x: center.x, y: center.y - offset)
    }

    var emoji: String {
        switch type {
        case .restaurant:
            if name.contains("Pizza") { return "🍕" }
            if name.contains("Burger") { return "🍔" }
            if name.contains("Sushi") { return "🍣" }
            if name.contains("Taco") { return "🌮" }
            if name.contains("Noodle") { return "🍜" }
            if name.contains("Coffee") { return "☕" }
            return "🍽️"
        case .office: return "🏢"
        case .house: return "🏠"
        case .warehouse: return "📦"
        case .park: return "🌳"
        }
    }
}

nonisolated enum GamePhase: Sendable {
    case menu
    case playing
    case gameOver
}

nonisolated struct Mission: Sendable {
    let type: MissionType
    let pickup: CityLocation
    let delivery: CityLocation
    var pickedUp: Bool = false
}

nonisolated enum SoundEffect: Sendable {
    case pickup
    case delivery
    case crash
    case policeSiren
    case catMeow
    case glassCrash
}

nonisolated enum Waveform: Sendable {
    case sine
    case square
    case triangle
    case noise
}

// MARK: - Shop System (Stream B)

nonisolated enum ShopType: CaseIterable, Sendable, Hashable {
    case scooterStore, musicStore, paintStore, portalStore

    var name: String {
        switch self {
        case .scooterStore: "Moto Shop"
        case .musicStore: "Beat Store"
        case .paintStore: "Paint & Ride"
        case .portalStore: "Portal Hub"
        }
    }

    var emoji: String {
        switch self {
        case .scooterStore: "🛵"
        case .musicStore: "🎵"
        case .paintStore: "🎨"
        case .portalStore: "🌀"
        }
    }

    var signColor: UIColor {
        switch self {
        case .scooterStore: UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1)
        case .musicStore: UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1)
        case .paintStore: UIColor(red: 0.9, green: 0.3, blue: 0.7, alpha: 1)
        case .portalStore: UIColor(red: 0.5, green: 0.3, blue: 1.0, alpha: 1)
        }
    }
}

nonisolated struct Shop: Sendable {
    let type: ShopType
    let gridX: Int
    let gridY: Int

    var worldPosition: CGPoint {
        let x = CGFloat(gridX) * CityConfig.cellSize + CityConfig.roadWidth + CityConfig.blockSize / 2
        let y = CGFloat(gridY) * CityConfig.cellSize + CityConfig.roadWidth + CityConfig.blockSize / 2
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Scooter Tier (Stream B5)

nonisolated enum ScooterTier: Int, CaseIterable, Sendable, Hashable {
    case basic = 0, turbo = 1, racing = 2

    var displayName: String {
        switch self {
        case .basic: "Basic Scooter"
        case .turbo: "Turbo Scooter"
        case .racing: "Racing Scooter"
        }
    }

    var price: Int {
        switch self {
        case .basic: 0
        case .turbo: 200
        case .racing: 500
        }
    }

    var maxSpeed: CGFloat {
        switch self {
        case .basic: 280
        case .turbo: 340
        case .racing: 400
        }
    }

    var thrust: CGFloat {
        switch self {
        case .basic: 900
        case .turbo: 1100
        case .racing: 1300
        }
    }

    var turnSpeed: CGFloat {
        switch self {
        case .basic: 5.5
        case .turbo: 5.5
        case .racing: 6.5
        }
    }
}

// MARK: - Music Track (Stream B6)

nonisolated enum GameTrack: CaseIterable, Sendable, Hashable {
    case original, jazz, electronic, lofi
    case reggae, hiphop, latin, ambient

    var displayName: String {
        switch self {
        case .original: "City Rush"
        case .jazz: "Smooth Jazz"
        case .electronic: "Neon Electronic"
        case .lofi: "Chill Lo-Fi"
        case .reggae: "Reggae Vibes"
        case .hiphop: "Hip-Hop City"
        case .latin: "Latin Fire"
        case .ambient: "Midnight Ambient"
        }
    }

    var price: Int {
        switch self {
        case .original: 0
        case .jazz: 150
        case .electronic: 150
        case .lofi: 100
        case .reggae: 175
        case .hiphop: 175
        case .latin: 200
        case .ambient: 125
        }
    }

    var bpm: Double {
        switch self {
        case .original: 135
        case .jazz: 90
        case .electronic: 140
        case .lofi: 75
        case .reggae: 80.0
        case .hiphop: 95.0
        case .latin: 120.0
        case .ambient: 60.0
        }
    }

    var character: String {
        switch self {
        case .original: "Upbeat city vibes with a punchy beat"
        case .jazz: "Smooth & mellow with soft chord swings"
        case .electronic: "High-energy neon synth lead"
        case .lofi: "Chill, muffled beats to relax and deliver"
        case .reggae: "Laid-back island groove with offbeat skank guitar"
        case .hiphop: "Hard 808 kicks and trap-style hi-hats"
        case .latin: "Fiery clave rhythms and brass stabs"
        case .ambient: "Slow atmospheric pads for late-night rides"
        }
    }
}

// MARK: - Scooter Color (Stream B7)

nonisolated enum ScooterColor: CaseIterable, Sendable, Hashable {
    case yellow, red, blue, green, purple, gold

    var displayName: String {
        switch self {
        case .yellow: "Classic Yellow"
        case .red: "Racing Red"
        case .blue: "Ocean Blue"
        case .green: "Jungle Green"
        case .purple: "Royal Purple"
        case .gold: "Gold Rush"
        }
    }

    var price: Int {
        switch self {
        case .yellow: 0
        default: 75
        }
    }

    var bodyColor: UIColor {
        switch self {
        case .yellow: UIColor(red: 1.0, green: 0.82, blue: 0.1, alpha: 1)
        case .red: UIColor(red: 0.9, green: 0.15, blue: 0.15, alpha: 1)
        case .blue: UIColor(red: 0.15, green: 0.5, blue: 0.9, alpha: 1)
        case .green: UIColor(red: 0.2, green: 0.7, blue: 0.25, alpha: 1)
        case .purple: UIColor(red: 0.55, green: 0.15, blue: 0.85, alpha: 1)
        case .gold: UIColor(red: 0.85, green: 0.65, blue: 0.1, alpha: 1)
        }
    }

    var strokeColor: UIColor {
        switch self {
        case .yellow: UIColor(red: 0.85, green: 0.7, blue: 0.05, alpha: 1)
        case .red: UIColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 1)
        case .blue: UIColor(red: 0.1, green: 0.35, blue: 0.7, alpha: 1)
        case .green: UIColor(red: 0.1, green: 0.5, blue: 0.15, alpha: 1)
        case .purple: UIColor(red: 0.4, green: 0.05, blue: 0.65, alpha: 1)
        case .gold: UIColor(red: 0.65, green: 0.45, blue: 0.05, alpha: 1)
        }
    }
}

// MARK: - City Theme (Stream C2)

nonisolated struct CityTheme: @unchecked Sendable {
    let name: String
    let level: Int
    let roadColor: UIColor
    let sidewalkColor: UIColor
    let buildingColors: [UIColor]
    let backgroundColor: UIColor
    let trafficAccentColor: UIColor
    let skylineEmoji: String
    let musicTrack: GameTrack
    let policeStationGrid: (Int, Int)
}

extension CityTheme {
    static let newYork = CityTheme(
        name: "New York",
        level: 1,
        roadColor: UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1),
        sidewalkColor: UIColor(red: 0.38, green: 0.37, blue: 0.36, alpha: 1),
        buildingColors: [
            UIColor(red: 0.48, green: 0.50, blue: 0.56, alpha: 1), // steel-grey
            UIColor(red: 0.55, green: 0.28, blue: 0.22, alpha: 1), // red brick
            UIColor(red: 0.72, green: 0.68, blue: 0.58, alpha: 1), // beige limestone
            UIColor(red: 0.22, green: 0.26, blue: 0.32, alpha: 1), // dark glass
            UIColor(red: 0.55, green: 0.42, blue: 0.35, alpha: 1),
            UIColor(red: 0.60, green: 0.55, blue: 0.50, alpha: 1),
            UIColor(red: 0.52, green: 0.45, blue: 0.42, alpha: 1),
            UIColor(red: 0.65, green: 0.58, blue: 0.48, alpha: 1),
        ],
        backgroundColor: UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1),
        trafficAccentColor: UIColor(red: 1.0, green: 0.82, blue: 0.1, alpha: 1),
        skylineEmoji: "🗽",
        musicTrack: .original,
        policeStationGrid: (1, 1)
    )

    static let istanbul = CityTheme(
        name: "Istanbul",
        level: 2,
        roadColor: UIColor(red: 0.25, green: 0.22, blue: 0.18, alpha: 1),
        sidewalkColor: UIColor(red: 0.52, green: 0.46, blue: 0.38, alpha: 1),
        buildingColors: [
            UIColor(red: 0.72, green: 0.62, blue: 0.38, alpha: 1), // warm ochre
            UIColor(red: 0.72, green: 0.40, blue: 0.28, alpha: 1), // terracotta
            UIColor(red: 0.88, green: 0.84, blue: 0.74, alpha: 1), // cream
            UIColor(red: 0.72, green: 0.56, blue: 0.54, alpha: 1), // dusty rose
            UIColor(red: 0.65, green: 0.55, blue: 0.40, alpha: 1),
            UIColor(red: 0.60, green: 0.48, blue: 0.35, alpha: 1),
        ],
        backgroundColor: UIColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1),
        trafficAccentColor: UIColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1),
        skylineEmoji: "🕌",
        musicTrack: .jazz,
        policeStationGrid: (2, 2)
    )

    static let riyadh = CityTheme(
        name: "Riyadh",
        level: 3,
        roadColor: UIColor(red: 0.55, green: 0.50, blue: 0.40, alpha: 1),
        sidewalkColor: UIColor(red: 0.72, green: 0.66, blue: 0.54, alpha: 1),
        buildingColors: [
            UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1), // white marble
            UIColor(red: 0.82, green: 0.74, blue: 0.58, alpha: 1), // sand
            UIColor(red: 0.78, green: 0.75, blue: 0.70, alpha: 1), // light concrete
            UIColor(red: 0.88, green: 0.82, blue: 0.60, alpha: 1), // pale gold
            UIColor(red: 0.85, green: 0.80, blue: 0.70, alpha: 1),
            UIColor(red: 0.75, green: 0.70, blue: 0.60, alpha: 1),
        ],
        backgroundColor: UIColor(red: 0.60, green: 0.55, blue: 0.42, alpha: 1),
        trafficAccentColor: UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1),
        skylineEmoji: "🕋",
        musicTrack: .electronic,
        policeStationGrid: (1, 2)
    )

    // MARK: - Level 4-10 Cities

    static let tokyo = CityTheme(
        name: "Tokyo",
        level: 4,
        roadColor: UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1),
        sidewalkColor: UIColor(red: 0.18, green: 0.18, blue: 0.24, alpha: 1),
        buildingColors: [
            UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1), // midnight black
            UIColor(red: 0.65, green: 0.10, blue: 0.45, alpha: 1), // neon pink
            UIColor(red: 0.10, green: 0.55, blue: 0.75, alpha: 1), // neon cyan
            UIColor(red: 0.20, green: 0.18, blue: 0.30, alpha: 1), // deep indigo
            UIColor(red: 0.50, green: 0.12, blue: 0.60, alpha: 1), // electric violet
            UIColor(red: 0.15, green: 0.22, blue: 0.28, alpha: 1), // dark steel
            UIColor(red: 0.80, green: 0.10, blue: 0.30, alpha: 1), // hot red neon
            UIColor(red: 0.05, green: 0.40, blue: 0.50, alpha: 1), // teal glass
        ],
        backgroundColor: UIColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1),
        trafficAccentColor: UIColor(red: 0.90, green: 0.20, blue: 0.60, alpha: 1),
        skylineEmoji: "🗼",
        musicTrack: .electronic,
        policeStationGrid: (2, 7)
    )

    static let london = CityTheme(
        name: "London",
        level: 5,
        roadColor: UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1),
        sidewalkColor: UIColor(red: 0.45, green: 0.44, blue: 0.42, alpha: 1),
        buildingColors: [
            UIColor(red: 0.48, green: 0.44, blue: 0.40, alpha: 1), // grey stone
            UIColor(red: 0.55, green: 0.28, blue: 0.20, alpha: 1), // red brick
            UIColor(red: 0.62, green: 0.58, blue: 0.50, alpha: 1), // Portland stone
            UIColor(red: 0.38, green: 0.36, blue: 0.34, alpha: 1), // dark soot stone
            UIColor(red: 0.70, green: 0.65, blue: 0.55, alpha: 1), // pale limestone
            UIColor(red: 0.50, green: 0.42, blue: 0.36, alpha: 1), // warm brown brick
            UIColor(red: 0.35, green: 0.40, blue: 0.38, alpha: 1), // slate grey
            UIColor(red: 0.60, green: 0.52, blue: 0.44, alpha: 1), // sandstone
        ],
        backgroundColor: UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1),
        trafficAccentColor: UIColor(red: 0.85, green: 0.10, blue: 0.10, alpha: 1),
        skylineEmoji: "🎡",
        musicTrack: .jazz,
        policeStationGrid: (3, 1)
    )

    static let paris = CityTheme(
        name: "Paris",
        level: 6,
        roadColor: UIColor(red: 0.30, green: 0.28, blue: 0.26, alpha: 1),
        sidewalkColor: UIColor(red: 0.58, green: 0.55, blue: 0.50, alpha: 1),
        buildingColors: [
            UIColor(red: 0.90, green: 0.87, blue: 0.78, alpha: 1), // Haussmann cream
            UIColor(red: 0.82, green: 0.78, blue: 0.68, alpha: 1), // warm limestone
            UIColor(red: 0.78, green: 0.72, blue: 0.60, alpha: 1), // pale ochre
            UIColor(red: 0.88, green: 0.83, blue: 0.72, alpha: 1), // soft buff stone
            UIColor(red: 0.75, green: 0.68, blue: 0.55, alpha: 1), // golden beige
            UIColor(red: 0.70, green: 0.65, blue: 0.58, alpha: 1), // muted taupe
            UIColor(red: 0.85, green: 0.80, blue: 0.70, alpha: 1), // pale champagne
            UIColor(red: 0.65, green: 0.60, blue: 0.52, alpha: 1), // warm grey stone
        ],
        backgroundColor: UIColor(red: 0.26, green: 0.24, blue: 0.22, alpha: 1),
        trafficAccentColor: UIColor(red: 0.20, green: 0.30, blue: 0.70, alpha: 1),
        skylineEmoji: "🗼",
        musicTrack: .jazz,
        policeStationGrid: (7, 8)
    )

    static let saoPaulo = CityTheme(
        name: "Sao Paulo",
        level: 7,
        roadColor: UIColor(red: 0.22, green: 0.22, blue: 0.20, alpha: 1),
        sidewalkColor: UIColor(red: 0.42, green: 0.40, blue: 0.36, alpha: 1),
        buildingColors: [
            UIColor(red: 0.75, green: 0.35, blue: 0.20, alpha: 1), // vivid terracotta
            UIColor(red: 0.25, green: 0.60, blue: 0.35, alpha: 1), // tropical green
            UIColor(red: 0.88, green: 0.70, blue: 0.18, alpha: 1), // bright yellow
            UIColor(red: 0.20, green: 0.40, blue: 0.75, alpha: 1), // electric blue
            UIColor(red: 0.72, green: 0.28, blue: 0.55, alpha: 1), // bold magenta
            UIColor(red: 0.58, green: 0.58, blue: 0.55, alpha: 1), // concrete grey
            UIColor(red: 0.85, green: 0.45, blue: 0.15, alpha: 1), // warm orange
            UIColor(red: 0.35, green: 0.65, blue: 0.60, alpha: 1), // teal graffiti
        ],
        backgroundColor: UIColor(red: 0.18, green: 0.18, blue: 0.16, alpha: 1),
        trafficAccentColor: UIColor(red: 0.95, green: 0.75, blue: 0.10, alpha: 1),
        skylineEmoji: "🌴",
        musicTrack: .original,
        policeStationGrid: (1, 8)
    )

    static let mumbai = CityTheme(
        name: "Mumbai",
        level: 8,
        roadColor: UIColor(red: 0.32, green: 0.28, blue: 0.24, alpha: 1),
        sidewalkColor: UIColor(red: 0.55, green: 0.48, blue: 0.40, alpha: 1),
        buildingColors: [
            UIColor(red: 0.78, green: 0.52, blue: 0.32, alpha: 1), // terracotta orange
            UIColor(red: 0.85, green: 0.72, blue: 0.45, alpha: 1), // warm ochre
            UIColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1), // colonial white
            UIColor(red: 0.62, green: 0.50, blue: 0.38, alpha: 1), // dusky brown
            UIColor(red: 0.30, green: 0.45, blue: 0.60, alpha: 1), // modern glass blue
            UIColor(red: 0.75, green: 0.62, blue: 0.50, alpha: 1), // warm sand
            UIColor(red: 0.45, green: 0.38, blue: 0.32, alpha: 1), // dark teak
            UIColor(red: 0.88, green: 0.80, blue: 0.60, alpha: 1), // pale gold plaster
        ],
        backgroundColor: UIColor(red: 0.28, green: 0.22, blue: 0.18, alpha: 1),
        trafficAccentColor: UIColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 1),
        skylineEmoji: "🌊",
        musicTrack: .original,
        policeStationGrid: (8, 2)
    )

    static let lagos = CityTheme(
        name: "Lagos",
        level: 9,
        roadColor: UIColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1),
        sidewalkColor: UIColor(red: 0.55, green: 0.42, blue: 0.30, alpha: 1),
        buildingColors: [
            UIColor(red: 0.82, green: 0.35, blue: 0.15, alpha: 1), // laterite red-orange
            UIColor(red: 0.25, green: 0.62, blue: 0.30, alpha: 1), // lush tropical green
            UIColor(red: 0.92, green: 0.78, blue: 0.20, alpha: 1), // vivid yellow
            UIColor(red: 0.15, green: 0.45, blue: 0.80, alpha: 1), // primary blue
            UIColor(red: 0.70, green: 0.28, blue: 0.18, alpha: 1), // deep red clay
            UIColor(red: 0.88, green: 0.58, blue: 0.22, alpha: 1), // orange clay
            UIColor(red: 0.40, green: 0.70, blue: 0.40, alpha: 1), // palm green
            UIColor(red: 0.95, green: 0.92, blue: 0.80, alpha: 1), // white render
        ],
        backgroundColor: UIColor(red: 0.30, green: 0.20, blue: 0.14, alpha: 1),
        trafficAccentColor: UIColor(red: 0.95, green: 0.70, blue: 0.05, alpha: 1),
        skylineEmoji: "🌍",
        musicTrack: .original,
        policeStationGrid: (2, 1)
    )

    static let sydney = CityTheme(
        name: "Sydney",
        level: 10,
        roadColor: UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1),
        sidewalkColor: UIColor(red: 0.55, green: 0.52, blue: 0.46, alpha: 1),
        buildingColors: [
            UIColor(red: 0.82, green: 0.72, blue: 0.58, alpha: 1), // Hawkesbury sandstone
            UIColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1), // bright white modern
            UIColor(red: 0.30, green: 0.55, blue: 0.80, alpha: 1), // harbour blue glass
            UIColor(red: 0.70, green: 0.62, blue: 0.50, alpha: 1), // warm sandstone
            UIColor(red: 0.55, green: 0.70, blue: 0.80, alpha: 1), // sky-reflect blue
            UIColor(red: 0.85, green: 0.82, blue: 0.75, alpha: 1), // pale buff
            UIColor(red: 0.40, green: 0.60, blue: 0.70, alpha: 1), // coastal teal
            UIColor(red: 0.75, green: 0.68, blue: 0.58, alpha: 1), // terracotta tile
        ],
        backgroundColor: UIColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1),
        trafficAccentColor: UIColor(red: 0.10, green: 0.55, blue: 0.90, alpha: 1),
        skylineEmoji: "🦘",
        musicTrack: .electronic,
        policeStationGrid: (7, 2)
    )

    static func theme(for level: Int) -> CityTheme {
        switch level {
        case 2: return .istanbul
        case 3: return .riyadh
        case 4: return .tokyo
        case 5: return .london
        case 6: return .paris
        case 7: return .saoPaulo
        case 8: return .mumbai
        case 9: return .lagos
        case 10: return .sydney
        default: return .newYork
        }
    }
}
