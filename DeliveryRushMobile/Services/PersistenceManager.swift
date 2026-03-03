import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let defaults = UserDefaults.standard

    private enum Key: String {
        case money, totalDeliveries, highScore
        case isRightHanded, musicVolume
    }

    func hasSavedGame() -> Bool {
        defaults.object(forKey: Key.money.rawValue) != nil
    }

    // MARK: - Save game state
    func save(viewModel: GameViewModel) {
        defaults.set(viewModel.money, forKey: Key.money.rawValue)
        defaults.set(viewModel.totalDeliveries, forKey: Key.totalDeliveries.rawValue)
        defaults.set(viewModel.highScore, forKey: Key.highScore.rawValue)
    }

    // MARK: - Load into viewModel
    func load(into viewModel: GameViewModel) {
        guard defaults.object(forKey: Key.money.rawValue) != nil else { return } // No saved state

        viewModel.money = defaults.integer(forKey: Key.money.rawValue)
        viewModel.totalDeliveries = defaults.integer(forKey: Key.totalDeliveries.rawValue)
        viewModel.highScore = defaults.integer(forKey: Key.highScore.rawValue)
    }

    // MARK: - Settings
    var isRightHanded: Bool {
        get { defaults.bool(forKey: Key.isRightHanded.rawValue) }
        set { defaults.set(newValue, forKey: Key.isRightHanded.rawValue) }
    }

    var musicVolume: Float {
        get {
            let v = defaults.float(forKey: Key.musicVolume.rawValue)
            return v == 0 ? 0.18 : v // default 0.18 matches SoundManager default
        }
        set { defaults.set(newValue, forKey: Key.musicVolume.rawValue) }
    }

    func clearSave() {
        // Remove only game progress keys, not settings
        let progressKeys: [Key] = [.money, .totalDeliveries, .highScore]
        progressKeys.forEach { defaults.removeObject(forKey: $0.rawValue) }
    }
}
