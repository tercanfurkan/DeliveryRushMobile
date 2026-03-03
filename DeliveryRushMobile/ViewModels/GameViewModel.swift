import SwiftUI
import SpriteKit

@Observable
class GameViewModel {
    var money: Int = 100
    var missionTimeRemaining: TimeInterval = 0
    var currentMission: Mission?
    var gamePhase: GamePhase = .menu
    var totalDeliveries: Int = 0
    var highScore: Int = 0
    var joystickDirection: CGVector = .zero
    var throwRequested: Bool = false
    var canThrow: Bool = false
    var showCrashFlash: Bool = false
    var showDeliveryComplete: Bool = false
    var lastEarned: Int = 0
    var missionMessage: String = ""
    var missionIconName: String? = nil
    var policeAlert: Bool = false
    var playerPosition: CGPoint = .zero

    // D1 - Police Chase Distance
    var policeChaseDistance: CGFloat = .infinity

    // B3 - Shop Proximity
    var nearbyShop: Shop? = nil
    var isShopOpen: Bool = false

    // C1 - Level Progression
    var currentLevel: Int = 1
    var deliveriesThisLevel: Int = 0
    var pendingLevelTransition: Bool = false

    // C5 - Current Theme
    var currentTheme: CityTheme = .newYork

    // B5 - Scooter
    var equippedScooter: ScooterTier = .basic
    var ownedScooters: Set<ScooterTier> = [.basic]

    // B6 - Music
    var activeTrack: GameTrack = .original
    var ownedTracks: Set<GameTrack> = [.original]

    // B7 - Paint
    var scooterColor: ScooterColor = .yellow
    var ownedColors: Set<ScooterColor> = [.yellow]

    var gameScene: GameScene?
    let soundManager = SoundManager()

    // B2 - Shops
    var shops: [Shop] = []

    var pickupMarkerPosition: CGPoint? {
        guard let mission = currentMission, !mission.pickedUp else { return nil }
        return mission.pickup.markerPosition
    }

    var deliveryMarkerPosition: CGPoint? {
        guard let mission = currentMission, mission.pickedUp else { return nil }
        return mission.delivery.markerPosition
    }

    private let cityLocations: [CityLocation] = [
        CityLocation(name: "Pizza Palace", gridX: 2, gridY: 3, type: .restaurant),
        CityLocation(name: "Burger Joint", gridX: 5, gridY: 1, type: .restaurant),
        CityLocation(name: "Sushi Express", gridX: 8, gridY: 7, type: .restaurant),
        CityLocation(name: "Taco Stand", gridX: 1, gridY: 8, type: .restaurant),
        CityLocation(name: "Noodle House", gridX: 6, gridY: 3, type: .restaurant),
        CityLocation(name: "Coffee Corner", gridX: 3, gridY: 9, type: .restaurant),
        CityLocation(name: "Tech Corp", gridX: 7, gridY: 2, type: .office),
        CityLocation(name: "Law Firm", gridX: 4, gridY: 4, type: .office),
        CityLocation(name: "Bank Tower", gridX: 3, gridY: 6, type: .office),
        CityLocation(name: "Startup Hub", gridX: 6, gridY: 8, type: .office),
        CityLocation(name: "Oak Home", gridX: 3, gridY: 1, type: .house),
        CityLocation(name: "Maple Apt", gridX: 6, gridY: 5, type: .house),
        CityLocation(name: "Pine Villa", gridX: 0, gridY: 4, type: .house),
        CityLocation(name: "Cedar Lodge", gridX: 8, gridY: 3, type: .house),
        CityLocation(name: "Elm Cottage", gridX: 1, gridY: 6, type: .house),
        CityLocation(name: "The Warehouse", gridX: 9, gridY: 9, type: .warehouse),
        CityLocation(name: "Dock Storage", gridX: 9, gridY: 1, type: .warehouse),
        CityLocation(name: "Old Factory", gridX: 0, gridY: 8, type: .warehouse),
    ]

    init() {
        soundManager.setup()
    }

    // MARK: - Shop Generation (B2)

    func generateShops() {
        let usedGrids = Set(cityLocations.map { "\($0.gridX)_\($0.gridY)" })
        let shopTypes = ShopType.allCases.shuffled()
        var result: [Shop] = []

        // Quadrant definitions: (xRange, yRange)
        let quadrants: [(ClosedRange<Int>, ClosedRange<Int>)] = [
            (0...4, 5...9), // top-left
            (5...9, 5...9), // top-right
            (0...4, 0...4), // bottom-left
            (5...9, 0...4), // bottom-right
        ]

        for (idx, quadrant) in quadrants.enumerated() {
            let shopType = shopTypes[idx]
            var placed = false
            var attempts = 0
            while !placed && attempts < 50 {
                let gx = Int.random(in: quadrant.0)
                let gy = Int.random(in: quadrant.1)
                let key = "\(gx)_\(gy)"
                if !usedGrids.contains(key) && !result.contains(where: { $0.gridX == gx && $0.gridY == gy }) {
                    result.append(Shop(type: shopType, gridX: gx, gridY: gy))
                    placed = true
                }
                attempts += 1
            }
        }

        shops = result
    }

    func startGame() {
        money = 100
        totalDeliveries = 0
        deliveriesThisLevel = 0
        currentLevel = 1
        gamePhase = .playing
        currentMission = nil
        canThrow = false
        policeAlert = false
        playerPosition = .zero
        policeChaseDistance = .infinity
        nearbyShop = nil
        isShopOpen = false
        pendingLevelTransition = false
        currentTheme = CityTheme.theme(for: currentLevel)

        generateShops()

        let scene = GameScene()
        scene.size = CGSize(width: 390, height: 844)
        scene.scaleMode = .resizeFill
        scene.viewModel = self
        scene.cityTheme = currentTheme
        gameScene = scene

        soundManager.startMusic()
        generateMission()
    }

    // MARK: - Level Progression (C1)

    func advanceLevel() {
        currentLevel += 1
        deliveriesThisLevel = 0
        pendingLevelTransition = true
        currentTheme = CityTheme.theme(for: currentLevel)

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.rebuildScene()
            self.pendingLevelTransition = false
        }
    }

    private func rebuildScene() {
        let scene = GameScene()
        scene.size = CGSize(width: 390, height: 844)
        scene.scaleMode = .resizeFill
        scene.viewModel = self
        scene.cityTheme = currentTheme
        gameScene = scene
        soundManager.switchTrack(currentTheme.musicTrack)
        generateMission()
    }

    func completeLevelTransition() {
        pendingLevelTransition = false
        rebuildScene()
    }

    func generateMission() {
        let weightedTypes: [MissionType]
        if totalDeliveries < 2 {
            weightedTypes = [.food, .food, .envelope]
        } else if totalDeliveries < 5 {
            weightedTypes = [.food, .envelope, .envelope, .mafia]
        } else {
            weightedTypes = MissionType.allCases + [.mafia]
        }

        let type = weightedTypes.randomElement() ?? .food

        var availableLocations = cityLocations.shuffled()
        let pickupLoc = availableLocations.removeFirst()
        let deliveryLoc = availableLocations.first { loc in
            let dx = abs(loc.gridX - pickupLoc.gridX)
            let dy = abs(loc.gridY - pickupLoc.gridY)
            return dx + dy >= 3
        } ?? availableLocations.first!

        let mission = Mission(type: type, pickup: pickupLoc, delivery: deliveryLoc)
        currentMission = mission
        missionTimeRemaining = type.timeLimit
        canThrow = false
        policeAlert = type.hasPolice

        missionIconName = pickupLoc.emoji
        missionMessage = "Pick up from \(pickupLoc.name)"
        gameScene?.setupMission(mission)
    }

    func pickupPackage() {
        guard var mission = currentMission, !mission.pickedUp else { return }
        mission.pickedUp = true
        currentMission = mission
        missionIconName = mission.delivery.emoji
        missionMessage = "Deliver to \(mission.delivery.name)!"
        gameScene?.showDeliveryMarker()
        soundManager.playEffect(.pickup)

        if mission.type.hasPolice {
            gameScene?.spawnPolice()
            soundManager.playEffect(.policeSiren)
        }
    }

    func deliverPackage() {
        guard let mission = currentMission, mission.pickedUp else { return }

        let timeBonus = Int(missionTimeRemaining / mission.type.timeLimit * 30)
        let earned = mission.type.reward + timeBonus
        money += earned
        totalDeliveries += 1
        deliveriesThisLevel += 1
        lastEarned = earned
        showDeliveryComplete = true
        canThrow = false
        policeAlert = false
        policeChaseDistance = .infinity

        gameScene?.clearMission()
        gameScene?.clearPolice()
        soundManager.playEffect(.delivery)

        missionIconName = nil
        missionMessage = "+$\(earned)! Nice delivery!"

        // C1 - check for level advance
        if deliveriesThisLevel >= 10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard self?.gamePhase == .playing else { return }
                self?.showDeliveryComplete = false
                self?.advanceLevel()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard self?.gamePhase == .playing else { return }
                self?.showDeliveryComplete = false
                self?.generateMission()
            }
        }
    }

    func applyCrashPenalty(_ amount: Int) {
        let penalty = min(amount, money)
        money -= penalty
        showCrashFlash = true
        soundManager.playEffect(.crash)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showCrashFlash = false
        }

        if money <= 0 {
            endGame()
        }
    }

    func missionTimedOut() {
        missionIconName = nil
        missionMessage = "⏰ Too slow! Mission failed!"
        currentMission = nil
        canThrow = false
        policeAlert = false
        policeChaseDistance = .infinity
        gameScene?.clearMission()
        gameScene?.clearPolice()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard self?.gamePhase == .playing else { return }
            self?.generateMission()
        }
    }

    func caughtByPolice() {
        missionIconName = nil
        missionMessage = "🚔 Busted! Taken to the police station."
        soundManager.playEffect(.policeSiren)
        applyCrashPenalty(50)
        currentMission = nil
        canThrow = false
        policeAlert = false
        policeChaseDistance = .infinity
        gameScene?.clearMission()
        gameScene?.clearPolice()
        gameScene?.respawnAtPoliceStation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard self?.gamePhase == .playing else { return }
            self?.generateMission()
        }
    }

    func endGame() {
        gamePhase = .gameOver
        highScore = max(highScore, totalDeliveries)
        gameScene?.isPaused = true
        soundManager.stopMusic()
    }

    // MARK: - Shop Purchase (B4-B8)

    func purchaseItem(shopType: ShopType, itemIndex: Int) {
        switch shopType {
        case .scooterStore:
            let tier = ScooterTier.allCases[itemIndex]
            guard !ownedScooters.contains(tier), money >= tier.price else { return }
            money -= tier.price
            ownedScooters.insert(tier)
            equippedScooter = tier

        case .musicStore:
            let track = GameTrack.allCases[itemIndex]
            guard !ownedTracks.contains(track), money >= track.price else { return }
            money -= track.price
            ownedTracks.insert(track)
            activeTrack = track
            soundManager.switchTrack(track)

        case .paintStore:
            let color = ScooterColor.allCases[itemIndex]
            guard !ownedColors.contains(color), money >= color.price else { return }
            money -= color.price
            ownedColors.insert(color)
            scooterColor = color

        case .portalStore:
            guard deliveriesThisLevel >= 8, money >= 100 else { return }
            money -= 100
            advanceLevel()
        }
    }

    func equipScooter(_ tier: ScooterTier) {
        guard ownedScooters.contains(tier) else { return }
        equippedScooter = tier
    }

    func equipTrack(_ track: GameTrack) {
        guard ownedTracks.contains(track) else { return }
        activeTrack = track
        soundManager.switchTrack(track)
    }

    func equipColor(_ color: ScooterColor) {
        guard ownedColors.contains(color) else { return }
        scooterColor = color
    }
}
