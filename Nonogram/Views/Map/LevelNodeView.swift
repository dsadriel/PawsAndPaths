import SwiftUI

/// Tactile circular level stepping-stone node matching the campaign reference art.
public struct LevelNodeView: View {
    @Environment(\.appTheme) private var appTheme

    public let level: CampaignLevel
    public let isUnlocked: Bool
    public let isCompleted: Bool
    public let isCurrent: Bool
    public let onTap: () -> Void

    public init(
        level: CampaignLevel,
        isUnlocked: Bool,
        isCompleted: Bool,
        isCurrent: Bool,
        onTap: @escaping () -> Void
    ) {
        self.level = level
        self.isUnlocked = isUnlocked
        self.isCompleted = isCompleted
        self.isCurrent = isCurrent
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: 2) {
            // Header: Mascot standing above current node, or checkmark badge for completed
            headerBadgeView
                .frame(height: 28)

            // Main circular node button
            Button(action: onTap) {
                ZStack {
                    // Outer 3D bevel / rim
                    Circle()
                        .fill(rimGradient)
                        .frame(width: 66, height: 66)
                        .shadow(color: .black.opacity(isUnlocked ? 0.25 : 0.1), radius: 3, x: 0, y: 4)

                    // Inner glossy disc
                    Circle()
                        .fill(discGradient)
                        .frame(width: 54, height: 54)
                        .overlay(
                            // Top gloss reflection
                            Circle()
                                .stroke(Color.white.opacity(isUnlocked ? 0.45 : 0.15), lineWidth: 2)
                                .blur(radius: 0.5)
                        )

                    // Node center emblem
                    if isUnlocked {
                        // Level number prominently displayed in the disc
                        Text("\(level.id)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.25), radius: 1, y: 1)
                    } else {
                        // Locked padlock
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.disabledAction.lip.opacity(0.8))
                    }
                }
            }
            .buttonStyle(NodeScaleButtonStyle())
            .disabled(!isUnlocked)
        }
    }

    // MARK: - Header Badge (Mascot or Completed Checkmark)
    private var headerBadgeView: some View {
        HStack(spacing: 3) {
            if isCurrent {
                // Mascot standing happily on top of active node!
                Image(appTheme.assets.mascotIdleAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .offset(y: 4)
                    .shadow(color: Theme.Colors.woodDark.opacity(0.2), radius: 2, y: 1)
            } else if isCompleted {
                // Subtle checkmark badge for completed level
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Theme.Colors.primaryAction.face)
                    .background(Circle().fill(Color.white).padding(2))
                    .shadow(color: Theme.Colors.woodDark.opacity(0.2), radius: 2, y: 1)
            } else {
                Spacer().frame(height: 20)
            }
        }
    }

    // MARK: - Gradients using Theme tokens
    private var rimGradient: LinearGradient {
        if isCurrent {
            return LinearGradient(
                colors: [Theme.Colors.rewardAction.face, Theme.Colors.rewardAction.lip],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isCompleted {
            return LinearGradient(
                colors: [Theme.Colors.primaryAction.face, Theme.Colors.primaryAction.lip],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isUnlocked {
            return LinearGradient(
                colors: [Theme.Colors.primaryAction.face, Theme.Colors.primaryAction.lip],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Theme.Colors.disabledAction.face, Theme.Colors.disabledAction.lip],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var discGradient: LinearGradient {
        if isCurrent {
            return LinearGradient(
                colors: [Theme.Colors.rewardAction.face.opacity(0.95), Theme.Colors.rewardAction.face],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isCompleted {
            return LinearGradient(
                colors: [Theme.Colors.primaryAction.face.opacity(0.95), Theme.Colors.primaryAction.face],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isUnlocked {
            return LinearGradient(
                colors: [Theme.Colors.primaryAction.face.opacity(0.95), Theme.Colors.primaryAction.face],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Theme.Colors.disabledAction.face.opacity(0.95), Theme.Colors.disabledAction.face],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// Springy button press style
private struct NodeScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
