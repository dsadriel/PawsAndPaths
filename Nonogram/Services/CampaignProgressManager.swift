import Foundation
import Combine

/// Manages progression, coin economy, and persistence for the campaign map.
@MainActor
public final class CampaignProgressManager: ObservableObject {
    public static let shared = CampaignProgressManager()

    private let unlockedLevelKey = "com.pawsandpaths.unlockedLevelIndex"
    private let completedLevelsKey = "com.pawsandpaths.completedLevels"
    private let coinsKey = "com.pawsandpaths.coins"
    private let hasInitializedKey = "com.pawsandpaths.hasInitializedCoins"

    @Published public private(set) var unlockedLevelIndex: Int
    @Published public private(set) var completedLevels: Set<Int>
    @Published public private(set) var coins: Int

    public init() {
        let savedUnlocked = UserDefaults.standard.integer(forKey: unlockedLevelKey)
        self.unlockedLevelIndex = max(1, savedUnlocked)

        if let savedCompleted = UserDefaults.standard.array(forKey: completedLevelsKey) as? [Int] {
            self.completedLevels = Set(savedCompleted)
        } else {
            self.completedLevels = []
        }

        // Initialize coins: new players start with 15 coins
        if UserDefaults.standard.bool(forKey: hasInitializedKey) {
            self.coins = UserDefaults.standard.integer(forKey: coinsKey)
        } else {
            self.coins = 15
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            UserDefaults.standard.set(15, forKey: coinsKey)
        }
    }

    /// Checks if a level is currently accessible.
    public func isUnlocked(id: Int) -> Bool {
        id <= unlockedLevelIndex
    }

    /// Checks if a level has been completed.
    public func isCompleted(id: Int) -> Bool {
        completedLevels.contains(id)
    }

    /// Records completion of a level: awards coins (5 for first completion, 1 for replay) and unlocks next level.
    @discardableResult
    public func completeLevel(id: Int, elapsedSeconds: Int = 0) -> Int {
        let isFirstCompletion = !completedLevels.contains(id)
        completedLevels.insert(id)

        let coinsEarned = isFirstCompletion ? 5 : 1
        coins += coinsEarned

        if id >= unlockedLevelIndex {
            unlockedLevelIndex = id + 1
        }

        save()
        return coinsEarned
    }

    /// Checks if player can afford a hint.
    public func canAffordHint(cost: Int = 3) -> Bool {
        coins >= cost
    }

    /// Deducts coins for purchasing a hint/clue. Returns true if successful.
    public func purchaseHint(cost: Int = 3) -> Bool {
        guard coins >= cost else { return false }
        coins -= cost
        save()
        return true
    }

    /// Adds coins (e.g. from special rewards or testing).
    public func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        save()
    }

    /// Resets progress for testing.
    public func resetProgress() {
        unlockedLevelIndex = 1
        completedLevels.removeAll()
        coins = 15
        save()
    }

    private func save() {
        UserDefaults.standard.set(unlockedLevelIndex, forKey: unlockedLevelKey)
        UserDefaults.standard.set(Array(completedLevels), forKey: completedLevelsKey)
        UserDefaults.standard.set(coins, forKey: coinsKey)
    }
}
