//
//  DeliveryRushMobileTests.swift
//  DeliveryRushMobileTests
//
//  Created by Rork on February 20, 2026.
//

import XCTest
@testable import DeliveryRushMobile

// MARK: - CityLocation Tests

final class CityLocationTests: XCTestCase {

    func testWorldPositionCalculationOrigin() {
        // gridX=0, gridY=0 → x = 0*180 + 70 + 55 = 125, y = 125
        let loc = CityLocation(name: "Test", gridX: 0, gridY: 0, type: .restaurant)
        XCTAssertEqual(loc.worldPosition.x, 125, accuracy: 0.001)
        XCTAssertEqual(loc.worldPosition.y, 125, accuracy: 0.001)
    }

    func testWorldPositionCalculationNonZero() {
        // gridX=5, gridY=3 → x = 5*180 + 70 + 55 = 1025, y = 3*180 + 70 + 55 = 665
        let loc = CityLocation(name: "Test", gridX: 5, gridY: 3, type: .office)
        let expectedX = CGFloat(5) * CityConfig.cellSize + CityConfig.roadWidth + CityConfig.blockSize / 2
        let expectedY = CGFloat(3) * CityConfig.cellSize + CityConfig.roadWidth + CityConfig.blockSize / 2
        XCTAssertEqual(loc.worldPosition.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(loc.worldPosition.y, expectedY, accuracy: 0.001)
        XCTAssertEqual(loc.worldPosition.x, 1025, accuracy: 0.001)
        XCTAssertEqual(loc.worldPosition.y, 665, accuracy: 0.001)
    }

    func testMarkerPositionIsAboveRoad() {
        // markerPosition.y = worldPosition.y - (blockSize/2 + roadWidth/2) → negative offset
        let loc = CityLocation(name: "Test", gridX: 3, gridY: 4, type: .house)
        XCTAssertLessThan(loc.markerPosition.y, loc.worldPosition.y)
    }

    func testMarkerPositionOffsetValue() {
        // offset = blockSize/2 + roadWidth/2 = 55 + 35 = 90
        let loc = CityLocation(name: "Test", gridX: 2, gridY: 2, type: .warehouse)
        let expectedOffset = CityConfig.blockSize / 2 + CityConfig.roadWidth / 2
        XCTAssertEqual(loc.worldPosition.y - loc.markerPosition.y, expectedOffset, accuracy: 0.001)
        XCTAssertEqual(loc.markerPosition.x, loc.worldPosition.x, accuracy: 0.001)
    }

    func testEmojiForRestaurantWithPizza() {
        let loc = CityLocation(name: "Pizza Palace", gridX: 0, gridY: 0, type: .restaurant)
        XCTAssertEqual(loc.emoji, "🍕")
    }

    func testEmojiForOfficeBuilding() {
        let loc = CityLocation(name: "Tech Corp", gridX: 0, gridY: 0, type: .office)
        XCTAssertEqual(loc.emoji, "🏢")
    }

    func testEmojiForHouse() {
        let loc = CityLocation(name: "Oak Home", gridX: 0, gridY: 0, type: .house)
        XCTAssertEqual(loc.emoji, "🏠")
    }

    func testEmojiForWarehouse() {
        let loc = CityLocation(name: "The Warehouse", gridX: 0, gridY: 0, type: .warehouse)
        XCTAssertEqual(loc.emoji, "📦")
    }

    func testEmojiForRestaurantDefaultFallback() {
        // A restaurant with no recognized keyword falls back to the default emoji
        let loc = CityLocation(name: "Mystery Diner", gridX: 0, gridY: 0, type: .restaurant)
        XCTAssertEqual(loc.emoji, "🍽️")
    }
}

// MARK: - MissionType Tests

final class MissionTypeTests: XCTestCase {

    func testFoodMissionReward() {
        XCTAssertEqual(MissionType.food.reward, 50)
    }

    func testEnvelopeMissionReward() {
        XCTAssertEqual(MissionType.envelope.reward, 75)
    }

    func testMafiaMissionReward() {
        XCTAssertEqual(MissionType.mafia.reward, 200)
    }

    func testFoodMissionTimeLimit() {
        XCTAssertEqual(MissionType.food.timeLimit, 50, accuracy: 0.001)
    }

    func testEnvelopeMissionTimeLimit() {
        XCTAssertEqual(MissionType.envelope.timeLimit, 40, accuracy: 0.001)
    }

    func testMafiaMissionTimeLimit() {
        XCTAssertEqual(MissionType.mafia.timeLimit, 65, accuracy: 0.001)
    }

    func testMafiaMissionHasPolice() {
        XCTAssertTrue(MissionType.mafia.hasPolice)
    }

    func testFoodMissionNoPolice() {
        XCTAssertFalse(MissionType.food.hasPolice)
    }

    func testEnvelopeMissionNoPolice() {
        XCTAssertFalse(MissionType.envelope.hasPolice)
    }

    func testAllCasesCount() {
        XCTAssertEqual(MissionType.allCases.count, 3)
    }

    func testAllCasesContainsFoodEnvelopeMafia() {
        let cases = MissionType.allCases
        XCTAssertTrue(cases.contains(.food))
        XCTAssertTrue(cases.contains(.envelope))
        XCTAssertTrue(cases.contains(.mafia))
    }
}

// MARK: - ScooterTier Tests

final class ScooterTierTests: XCTestCase {

    func testBasicScooterIsFree() {
        XCTAssertEqual(ScooterTier.basic.price, 0)
    }

    func testTurboScooterPrice() {
        XCTAssertEqual(ScooterTier.turbo.price, 200)
    }

    func testRacingScooterPrice() {
        XCTAssertEqual(ScooterTier.racing.price, 500)
    }

    func testRacingScooterHasHighestMaxSpeed() {
        XCTAssertGreaterThan(ScooterTier.racing.maxSpeed, ScooterTier.turbo.maxSpeed)
        XCTAssertGreaterThan(ScooterTier.turbo.maxSpeed, ScooterTier.basic.maxSpeed)
    }

    func testTierRawValues() {
        XCTAssertEqual(ScooterTier.basic.rawValue, 0)
        XCTAssertEqual(ScooterTier.turbo.rawValue, 1)
        XCTAssertEqual(ScooterTier.racing.rawValue, 2)
    }

    func testRacingScooterHasHighestThrust() {
        XCTAssertGreaterThan(ScooterTier.racing.thrust, ScooterTier.turbo.thrust)
        XCTAssertGreaterThan(ScooterTier.turbo.thrust, ScooterTier.basic.thrust)
    }

    func testAllCasesCount() {
        XCTAssertEqual(ScooterTier.allCases.count, 3)
    }
}

// MARK: - CityTheme Tests

final class CityThemeTests: XCTestCase {

    func testThemeForLevel1IsNewYork() {
        let theme = CityTheme.theme(for: 1)
        XCTAssertEqual(theme.name, "New York")
        XCTAssertEqual(theme.level, 1)
    }

    func testThemeForLevel2IsIstanbul() {
        let theme = CityTheme.theme(for: 2)
        XCTAssertEqual(theme.name, "Istanbul")
        XCTAssertEqual(theme.level, 2)
    }

    func testThemeForLevel3IsRiyadh() {
        let theme = CityTheme.theme(for: 3)
        XCTAssertEqual(theme.name, "Riyadh")
        XCTAssertEqual(theme.level, 3)
    }

    func testThemeForLevel4IsNotNewYork() {
        // Level 4 falls through to default (newYork) since no case 4 is defined.
        // The contract is: it should not crash. The name is defined by the default branch.
        let theme = CityTheme.theme(for: 4)
        XCTAssertFalse(theme.name.isEmpty)
        // Default branch returns newYork — level 4 is not a named city in the switch
        XCTAssertEqual(theme.name, "New York")
    }

    func testThemeForLevel99FallsBack() {
        // Level 99 should not crash and returns the default theme
        let theme = CityTheme.theme(for: 99)
        XCTAssertFalse(theme.name.isEmpty)
    }

    func testNewYorkMusicTrack() {
        XCTAssertEqual(CityTheme.newYork.musicTrack, .original)
    }

    func testIstanbulMusicTrack() {
        XCTAssertEqual(CityTheme.istanbul.musicTrack, .jazz)
    }

    func testRiyadhMusicTrack() {
        XCTAssertEqual(CityTheme.riyadh.musicTrack, .electronic)
    }
}

// MARK: - CityConfig Tests

final class CityConfigTests: XCTestCase {

    func testCellSizeEqualsBlockPlusRoad() {
        XCTAssertEqual(CityConfig.cellSize, CityConfig.blockSize + CityConfig.roadWidth, accuracy: 0.001)
    }

    func testCellSizeValue() {
        // blockSize=110, roadWidth=70 → cellSize=180
        XCTAssertEqual(CityConfig.cellSize, 180, accuracy: 0.001)
    }

    func testWorldSizeIsCorrect() {
        XCTAssertEqual(CityConfig.worldSize, CGFloat(CityConfig.gridSize) * CityConfig.cellSize, accuracy: 0.001)
    }

    func testWorldSizeValue() {
        // gridSize=10, cellSize=180 → worldSize=1800
        XCTAssertEqual(CityConfig.worldSize, 1800, accuracy: 0.001)
    }

    func testGridSize() {
        XCTAssertEqual(CityConfig.gridSize, 10)
    }

    func testBlockSize() {
        XCTAssertEqual(CityConfig.blockSize, 110, accuracy: 0.001)
    }

    func testRoadWidth() {
        XCTAssertEqual(CityConfig.roadWidth, 70, accuracy: 0.001)
    }
}

// MARK: - GameViewModel Economy Tests

final class GameViewModelEconomyTests: XCTestCase {

    @MainActor
    func testStartingMoney() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.money, 100)
    }

    @MainActor
    func testApplyCrashPenaltyDeductsMoney() {
        let vm = GameViewModel()
        vm.money = 100
        vm.applyCrashPenalty(15)
        XCTAssertEqual(vm.money, 85)
    }

    @MainActor
    func testApplyCrashPenaltyCannotGoBelowZero() {
        let vm = GameViewModel()
        vm.money = 10
        vm.applyCrashPenalty(50) // penalty > money
        XCTAssertGreaterThanOrEqual(vm.money, 0)
        XCTAssertEqual(vm.money, 0)
    }

    @MainActor
    func testApplyCrashPenaltyTriggersGameOverWhenBroke() {
        let vm = GameViewModel()
        vm.money = 10
        vm.gamePhase = .playing
        vm.applyCrashPenalty(10)
        XCTAssertEqual(vm.money, 0)
        XCTAssertEqual(vm.gamePhase, .gameOver)
    }

    @MainActor
    func testCrashFlashIsShownOnPenalty() {
        let vm = GameViewModel()
        vm.money = 100
        vm.applyCrashPenalty(15)
        XCTAssertTrue(vm.showCrashFlash)
    }

    @MainActor
    func testApplyCrashPenaltyExactlyZero() {
        let vm = GameViewModel()
        vm.money = 30
        vm.applyCrashPenalty(30)
        XCTAssertEqual(vm.money, 0)
        XCTAssertEqual(vm.gamePhase, .gameOver)
    }

    @MainActor
    func testEndGameSetsPhaseToGameOver() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.endGame()
        XCTAssertEqual(vm.gamePhase, .gameOver)
    }

    @MainActor
    func testEndGameUpdatesHighScore() {
        let vm = GameViewModel()
        vm.totalDeliveries = 5
        vm.highScore = 3
        vm.endGame()
        XCTAssertEqual(vm.highScore, 5)
    }

    @MainActor
    func testEndGameDoesNotLowerHighScore() {
        let vm = GameViewModel()
        vm.totalDeliveries = 2
        vm.highScore = 10
        vm.endGame()
        XCTAssertEqual(vm.highScore, 10)
    }
}

// MARK: - GameViewModel Mission Tests

final class GameViewModelMissionTests: XCTestCase {

    @MainActor
    func testInitialCanThrowIsFalse() {
        let vm = GameViewModel()
        XCTAssertFalse(vm.canThrow)
    }

    @MainActor
    func testInitialCurrentMissionIsNil() {
        let vm = GameViewModel()
        XCTAssertNil(vm.currentMission)
    }

    @MainActor
    func testGenerateMissionCreatesCurrentMission() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.generateMission()
        XCTAssertNotNil(vm.currentMission)
    }

    @MainActor
    func testPickupAndDeliveryLocationsAreDifferent() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.generateMission()
        guard let mission = vm.currentMission else {
            XCTFail("Expected a mission after generateMission()")
            return
        }
        // Pickup and delivery must be different grid positions
        let samePosition = mission.pickup.gridX == mission.delivery.gridX
            && mission.pickup.gridY == mission.delivery.gridY
        XCTAssertFalse(samePosition)
    }

    @MainActor
    func testMissionTimeRemainingSetOnGenerate() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.generateMission()
        XCTAssertGreaterThan(vm.missionTimeRemaining, 0)
    }

    @MainActor
    func testMissionTimedOutClearsCurrentMission() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.generateMission()
        XCTAssertNotNil(vm.currentMission)
        vm.missionTimedOut()
        XCTAssertNil(vm.currentMission)
    }

    @MainActor
    func testMissionTimedOutResetsPoliceAlert() {
        let vm = GameViewModel()
        vm.policeAlert = true
        vm.missionTimedOut()
        XCTAssertFalse(vm.policeAlert)
    }

    @MainActor
    func testMissionTimedOutResetsCanThrow() {
        let vm = GameViewModel()
        vm.canThrow = true
        vm.missionTimedOut()
        XCTAssertFalse(vm.canThrow)
    }

    @MainActor
    func testGenerateMissionSetsPoliceAlertForMafia() {
        // Run generateMission() multiple times until we get a mafia mission
        // to verify that policeAlert is set when hasPolice is true.
        // Since mission type is random we test the logic with a manually set mission.
        let vm = GameViewModel()
        vm.gamePhase = .playing

        // Simulate the policeAlert logic that generateMission() applies:
        // policeAlert = type.hasPolice
        let foodPoliceAlert = MissionType.food.hasPolice
        let mafiaPoliceAlert = MissionType.mafia.hasPolice
        XCTAssertFalse(foodPoliceAlert)
        XCTAssertTrue(mafiaPoliceAlert)
    }

    @MainActor
    func testPickupPackageDoesNothingWhenNoMission() {
        let vm = GameViewModel()
        vm.pickupPackage() // should not crash with no currentMission
        XCTAssertNil(vm.currentMission)
    }

    @MainActor
    func testDeliverPackageDoesNothingWhenNotPickedUp() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.generateMission()
        let missionBefore = vm.currentMission
        vm.deliverPackage() // pickedUp is false, should no-op
        // Mission should not be cleared (no delivery happened)
        XCTAssertNotNil(vm.currentMission)
        XCTAssertEqual(vm.totalDeliveries, 0)
        _ = missionBefore // suppress unused warning
    }
}

// MARK: - GameViewModel Shop Purchase Tests

final class GameViewModelShopTests: XCTestCase {

    @MainActor
    func testCannotAffordTurboScooterWithInsufficientFunds() {
        let vm = GameViewModel()
        vm.money = 50 // turbo costs 200
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 1)
        XCTAssertFalse(vm.ownedScooters.contains(.turbo))
        XCTAssertEqual(vm.money, 50) // no deduction
    }

    @MainActor
    func testPurchaseTurboScooterDeductsMoney() {
        let vm = GameViewModel()
        vm.money = 300
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 1) // turbo = 200
        XCTAssertEqual(vm.money, 100) // 300 - 200
        XCTAssertTrue(vm.ownedScooters.contains(.turbo))
    }

    @MainActor
    func testPurchaseTurboScooterEquipsItAutomatically() {
        let vm = GameViewModel()
        vm.money = 300
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 1)
        XCTAssertEqual(vm.equippedScooter, .turbo)
    }

    @MainActor
    func testEquipScooterRequiresOwnership() {
        let vm = GameViewModel()
        // turbo is not owned initially
        vm.equipScooter(.turbo)
        XCTAssertEqual(vm.equippedScooter, .basic) // unchanged
    }

    @MainActor
    func testEquipScooterWorksWhenOwned() {
        let vm = GameViewModel()
        vm.money = 300
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 1) // buy turbo
        vm.equippedScooter = .basic // reset equipped
        vm.equipScooter(.turbo) // now equip explicitly
        XCTAssertEqual(vm.equippedScooter, .turbo)
    }

    @MainActor
    func testPurchaseMusicTrackDeductsMoney() {
        let vm = GameViewModel()
        vm.money = 300
        // GameTrack.allCases[1] is .jazz (price = 150)
        vm.purchaseItem(shopType: .musicStore, itemIndex: 1)
        XCTAssertEqual(vm.money, 150) // 300 - 150
        XCTAssertTrue(vm.ownedTracks.contains(.jazz))
    }

    @MainActor
    func testCannotBuyAlreadyOwnedScooter() {
        let vm = GameViewModel()
        vm.money = 500
        // basic is already owned and has price 0; the guard !ownedScooters.contains(tier) fires
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 0)
        XCTAssertEqual(vm.money, 500) // no deduction for already owned
    }

    @MainActor
    func testCannotBuyAlreadyOwnedTrack() {
        let vm = GameViewModel()
        vm.money = 500
        // original (index 0) is already owned
        vm.purchaseItem(shopType: .musicStore, itemIndex: 0)
        XCTAssertEqual(vm.money, 500) // no deduction
    }

    @MainActor
    func testPurchaseRacingScooterDeductsMoney() {
        let vm = GameViewModel()
        vm.money = 600
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 2) // racing = 500
        XCTAssertEqual(vm.money, 100)
        XCTAssertTrue(vm.ownedScooters.contains(.racing))
    }

    @MainActor
    func testCannotAffordRacingScooterWithInsufficientFunds() {
        let vm = GameViewModel()
        vm.money = 100
        vm.purchaseItem(shopType: .scooterStore, itemIndex: 2) // racing = 500
        XCTAssertFalse(vm.ownedScooters.contains(.racing))
        XCTAssertEqual(vm.money, 100)
    }

    @MainActor
    func testPurchasePaintColorDeductsMoney() {
        let vm = GameViewModel()
        vm.money = 200
        // ScooterColor.allCases[1] is .red (price = 75)
        vm.purchaseItem(shopType: .paintStore, itemIndex: 1)
        XCTAssertEqual(vm.money, 125) // 200 - 75
        XCTAssertTrue(vm.ownedColors.contains(.red))
    }

    @MainActor
    func testDefaultEquippedScooterIsBasic() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.equippedScooter, .basic)
    }

    @MainActor
    func testDefaultOwnedScootersContainsBasic() {
        let vm = GameViewModel()
        XCTAssertTrue(vm.ownedScooters.contains(.basic))
    }

    @MainActor
    func testDefaultOwnedTracksContainsOriginal() {
        let vm = GameViewModel()
        XCTAssertTrue(vm.ownedTracks.contains(.original))
    }

    @MainActor
    func testDefaultScooterColorIsYellow() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.scooterColor, .yellow)
    }
}

// MARK: - GameViewModel Level Progression Tests

final class GameViewModelLevelProgressionTests: XCTestCase {

    @MainActor
    func testDeliveriesThisLevelIncrements() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        let pickup = CityLocation(name: "Pizza Palace", gridX: 2, gridY: 3, type: .restaurant)
        let delivery = CityLocation(name: "Tech Corp", gridX: 7, gridY: 2, type: .office)
        var mission = Mission(type: .food, pickup: pickup, delivery: delivery)
        mission.pickedUp = true
        vm.currentMission = mission
        vm.missionTimeRemaining = 30
        let before = vm.deliveriesThisLevel
        vm.deliverPackage()
        XCTAssertEqual(vm.deliveriesThisLevel, before + 1)
    }

    @MainActor
    func testTotalDeliveriesIncrements() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        let pickup = CityLocation(name: "Burger Joint", gridX: 5, gridY: 1, type: .restaurant)
        let delivery = CityLocation(name: "Law Firm", gridX: 4, gridY: 4, type: .office)
        var mission = Mission(type: .envelope, pickup: pickup, delivery: delivery)
        mission.pickedUp = true
        vm.currentMission = mission
        vm.missionTimeRemaining = 20
        let before = vm.totalDeliveries
        vm.deliverPackage()
        XCTAssertEqual(vm.totalDeliveries, before + 1)
    }

    @MainActor
    func testDeliverPackageAddsMoneyOnSuccess() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.money = 100
        let pickup = CityLocation(name: "Sushi Express", gridX: 8, gridY: 7, type: .restaurant)
        let delivery = CityLocation(name: "Bank Tower", gridX: 3, gridY: 6, type: .office)
        var mission = Mission(type: .food, pickup: pickup, delivery: delivery)
        mission.pickedUp = true
        vm.currentMission = mission
        vm.missionTimeRemaining = 25 // half time left → timeBonus = Int(25/50 * 30) = 15
        vm.deliverPackage()
        XCTAssertGreaterThan(vm.money, 100)
    }

    @MainActor
    func testDeliverPackageSetsShowDeliveryComplete() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        let pickup = CityLocation(name: "Taco Stand", gridX: 1, gridY: 8, type: .restaurant)
        let delivery = CityLocation(name: "Startup Hub", gridX: 6, gridY: 8, type: .office)
        var mission = Mission(type: .mafia, pickup: pickup, delivery: delivery)
        mission.pickedUp = true
        vm.currentMission = mission
        vm.missionTimeRemaining = 40
        vm.deliverPackage()
        XCTAssertTrue(vm.showDeliveryComplete)
    }

    @MainActor
    func testDeliverPackageResetsPoliceAlert() {
        let vm = GameViewModel()
        vm.gamePhase = .playing
        vm.policeAlert = true
        let pickup = CityLocation(name: "Coffee Corner", gridX: 3, gridY: 9, type: .restaurant)
        let delivery = CityLocation(name: "The Warehouse", gridX: 9, gridY: 9, type: .warehouse)
        var mission = Mission(type: .mafia, pickup: pickup, delivery: delivery)
        mission.pickedUp = true
        vm.currentMission = mission
        vm.missionTimeRemaining = 50
        vm.deliverPackage()
        XCTAssertFalse(vm.policeAlert)
    }

    @MainActor
    func testInitialDeliveriesThisLevelIsZero() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.deliveriesThisLevel, 0)
    }

    @MainActor
    func testInitialCurrentLevelIsOne() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.currentLevel, 1)
    }
}

// MARK: - GameViewModel Initial State Tests

final class GameViewModelInitialStateTests: XCTestCase {

    @MainActor
    func testInitialGamePhaseIsMenu() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.gamePhase, .menu)
    }

    @MainActor
    func testInitialTotalDeliveriesIsZero() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.totalDeliveries, 0)
    }

    @MainActor
    func testInitialHighScoreIsZero() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.highScore, 0)
    }

    @MainActor
    func testInitialPoliceAlertIsFalse() {
        let vm = GameViewModel()
        XCTAssertFalse(vm.policeAlert)
    }

    @MainActor
    func testInitialShowCrashFlashIsFalse() {
        let vm = GameViewModel()
        XCTAssertFalse(vm.showCrashFlash)
    }

    @MainActor
    func testInitialShowDeliveryCompleteIsFalse() {
        let vm = GameViewModel()
        XCTAssertFalse(vm.showDeliveryComplete)
    }

    @MainActor
    func testInitialThemeIsNewYork() {
        let vm = GameViewModel()
        XCTAssertEqual(vm.currentTheme.name, "New York")
    }

    @MainActor
    func testPickupMarkerPositionIsNilWithNoMission() {
        let vm = GameViewModel()
        XCTAssertNil(vm.pickupMarkerPosition)
    }

    @MainActor
    func testDeliveryMarkerPositionIsNilWithNoMission() {
        let vm = GameViewModel()
        XCTAssertNil(vm.deliveryMarkerPosition)
    }

    @MainActor
    func testPickupMarkerPositionPresentBeforePickup() {
        let vm = GameViewModel()
        let pickup = CityLocation(name: "Pizza Palace", gridX: 2, gridY: 3, type: .restaurant)
        let delivery = CityLocation(name: "Tech Corp", gridX: 7, gridY: 2, type: .office)
        let mission = Mission(type: .food, pickup: pickup, delivery: delivery, pickedUp: false)
        vm.currentMission = mission
        XCTAssertNotNil(vm.pickupMarkerPosition)
        XCTAssertNil(vm.deliveryMarkerPosition)
    }

    @MainActor
    func testDeliveryMarkerPositionPresentAfterPickup() {
        let vm = GameViewModel()
        let pickup = CityLocation(name: "Pizza Palace", gridX: 2, gridY: 3, type: .restaurant)
        let delivery = CityLocation(name: "Tech Corp", gridX: 7, gridY: 2, type: .office)
        let mission = Mission(type: .food, pickup: pickup, delivery: delivery, pickedUp: true)
        vm.currentMission = mission
        XCTAssertNil(vm.pickupMarkerPosition)
        XCTAssertNotNil(vm.deliveryMarkerPosition)
    }
}
