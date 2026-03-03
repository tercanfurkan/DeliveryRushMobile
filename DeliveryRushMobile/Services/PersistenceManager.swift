import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let defaults = UserDefaults.standard

    private enum Key: String {
        case money, totalDeliveries, highScore
        case currentLevel, deliveriesThisLevel
        case equippedScooter, ownedScooters
        case activeTrack, ownedTracks
        case scooterColor, ownedColors
        case isRightHanded, musicVolume
    }

    func hasSavedGame() -> Bool {
        defaults.object(forKey: Key.money.rawValue) != nil
    }

    // MARK: - Save

    func save(viewModel: GameViewModel) {
        defaults.set(viewModel.money, forKey: Key.money.rawValue)
        defaults.set(viewModel.totalDeliveries, forKey: Key.totalDeliveries.rawValue)
        defaults.set(viewModel.highScore, forKey: Key.highScore.rawValue)
        defaults.set(viewModel.currentLevel, forKey: Key.currentLevel.rawValue)
        defaults.set(viewModel.deliveriesThisLevel, forKey: Key.deliveriesThisLevel.rawValue)

        defaults.set(viewModel.equippedScooter.rawValue, forKey: Key.equippedScooter.rawValue)
        defaults.set(viewModel.ownedScooters.map(\.rawValue), forKey: Key.ownedScooters.rawValue)

        let allTracks = GameTrack.allCases
        defaults.set(allTracks.firstIndex(of: viewModel.activeTrack) ?? 0, forKey: Key.activeTrack.rawValue)
        defaults.set(
            viewModel.ownedTracks.compactMap { allTracks.firstIndex(of: $0) },
            forKey: Key.ownedTracks.rawValue
        )

        let allColors = ScooterColor.allCases
        defaults.set(allColors.firstIndex(of: viewModel.scooterColor) ?? 0, forKey: Key.scooterColor.rawValue)
        defaults.set(
            viewModel.ownedColors.compactMap { allColors.firstIndex(of: $0) },
            forKey: Key.ownedColors.rawValue
        )
    }

    // MARK: - Load

    func load(into viewModel: GameViewModel) {
        guard defaults.object(forKey: Key.money.rawValue) != nil else { return }

        viewModel.money = defaults.integer(forKey: Key.money.rawValue)
        viewModel.totalDeliveries = defaults.integer(forKey: Key.totalDeliveries.rawValue)
        viewModel.highScore = defaults.integer(forKey: Key.highScore.rawValue)

        let level = defaults.integer(forKey: Key.currentLevel.rawValue)
        viewModel.currentLevel = level > 0 ? level : 1
        viewModel.deliveriesThisLevel = defaults.integer(forKey: Key.deliveriesThisLevel.rawValue)

        let scooterRaw = defaults.integer(forKey: Key.equippedScooter.rawValue)
        viewModel.equippedScooter = ScooterTier(rawValue: scooterRaw) ?? .basic
        if let rawList = defaults.array(forKey: Key.ownedScooters.rawValue) as? [Int] {
            let restored = Set(rawList.compactMap { ScooterTier(rawValue: $0) })
            viewModel.ownedScooters = restored.isEmpty ? [.basic] : restored
        }

        let allTracks = GameTrack.allCases
        let trackIdx = defaults.integer(forKey: Key.activeTrack.rawValue)
        viewModel.activeTrack = allTracks.indices.contains(trackIdx) ? allTracks[trackIdx] : .original
        if let idxList = defaults.array(forKey: Key.ownedTracks.rawValue) as? [Int] {
            let restored = Set(idxList.compactMap { allTracks.indices.contains($0) ? allTracks[$0] : nil })
            viewModel.ownedTracks = restored.isEmpty ? [.original] : restored
        }

        let allColors = ScooterColor.allCases
        let colorIdx = defaults.integer(forKey: Key.scooterColor.rawValue)
        viewModel.scooterColor = allColors.indices.contains(colorIdx) ? allColors[colorIdx] : .yellow
        if let idxList = defaults.array(forKey: Key.ownedColors.rawValue) as? [Int] {
            let restored = Set(idxList.compactMap { allColors.indices.contains($0) ? allColors[$0] : nil })
            viewModel.ownedColors = restored.isEmpty ? [.yellow] : restored
        }
    }

    // MARK: - Settings (never cleared by clearSave)

    var isRightHanded: Bool {
        get { defaults.bool(forKey: Key.isRightHanded.rawValue) }
        set { defaults.set(newValue, forKey: Key.isRightHanded.rawValue) }
    }

    var musicVolume: Float {
        get {
            let v = defaults.float(forKey: Key.musicVolume.rawValue)
            return v == 0 ? 0.18 : v
        }
        set { defaults.set(newValue, forKey: Key.musicVolume.rawValue) }
    }

    func clearSave() {
        let progressKeys: [Key] = [
            .money, .totalDeliveries, .highScore,
            .currentLevel, .deliveriesThisLevel,
            .equippedScooter, .ownedScooters,
            .activeTrack, .ownedTracks,
            .scooterColor, .ownedColors
        ]
        progressKeys.forEach { defaults.removeObject(forKey: $0.rawValue) }
    }
}
