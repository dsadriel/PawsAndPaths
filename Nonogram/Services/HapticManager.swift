import UIKit

/// Manages tactile haptic feedback for cozy grid interactions.
@MainActor
public final class HapticManager {
    public static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
    }

    /// Feedback when placing or toggling a path tile.
    public func pathPlaced() {
        rigidImpact.impactOccurred(intensity: 0.75)
    }

    /// Feedback when marking a cross tile.
    public func crossPlaced() {
        lightImpact.impactOccurred(intensity: 0.5)
    }

    /// Feedback when clearing a tile.
    public func cellCleared() {
        lightImpact.impactOccurred(intensity: 0.3)
    }

    /// Feedback when a row or column clue is successfully satisfied.
    public func clueSatisfied() {
        mediumImpact.impactOccurred(intensity: 0.8)
    }

    /// Feedback when a reward or star is earned.
    public func rewardCollected() {
        mediumImpact.impactOccurred(intensity: 0.7)
    }

    /// Feedback when tapping buttons or interactive controls.
    public func buttonPress() {
        lightImpact.impactOccurred(intensity: 0.6)
    }

    /// Feedback when selecting items or changing themes.
    public func tapSelection() {
        lightImpact.impactOccurred(intensity: 0.45)
    }

    /// Feedback on puzzle victory.
    public func victory() {
        notification.notificationOccurred(.success)
    }
}
