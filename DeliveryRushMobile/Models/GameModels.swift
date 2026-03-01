import Foundation
import CoreGraphics

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
}

nonisolated enum Waveform: Sendable {
    case sine
    case square
    case triangle
    case noise
}
