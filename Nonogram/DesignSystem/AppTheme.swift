import SwiftUI

// MARK: - AppTheme Protocol & Structures

public struct ThemeColors: Sendable {
    public let sky: Color
    public let ground: Color
    public let board: Color
    public let boardCell: Color
    public let track: Color
    public let accent: Color

    public init(
        sky: Color,
        ground: Color,
        board: Color,
        boardCell: Color,
        track: Color,
        accent: Color
    ) {
        self.sky = sky
        self.ground = ground
        self.board = board
        self.boardCell = boardCell
        self.track = track
        self.accent = accent
    }
}

public struct ThemeAssets: Sendable {
    public let backgroundImageName: String?
    public let treePropImageName: String?
    public let rockPropImageName: String?
    public let flowerPropImageName: String?
    public let mascotIdleAssetName: String
    public let mascotWalkAssetName: String
    public let mascotCelebrateAssetName: String
    public let targetItemAssetName: String

    public init(
        backgroundImageName: String? = nil,
        treePropImageName: String? = nil,
        rockPropImageName: String? = nil,
        flowerPropImageName: String? = nil,
        mascotIdleAssetName: String,
        mascotWalkAssetName: String,
        mascotCelebrateAssetName: String,
        targetItemAssetName: String
    ) {
        self.backgroundImageName = backgroundImageName
        self.treePropImageName = treePropImageName
        self.rockPropImageName = rockPropImageName
        self.flowerPropImageName = flowerPropImageName
        self.mascotIdleAssetName = mascotIdleAssetName
        self.mascotWalkAssetName = mascotWalkAssetName
        self.mascotCelebrateAssetName = mascotCelebrateAssetName
        self.targetItemAssetName = targetItemAssetName
    }
}

public struct ThemeBoardStyle: Sendable {
    public let cornerRadius: CGFloat
    public let cardPadding: CGFloat
    public let cellCornerRadiusRatio: CGFloat

    public init(
        cornerRadius: CGFloat = 16,
        cardPadding: CGFloat = 8,
        cellCornerRadiusRatio: CGFloat = 0.16
    ) {
        self.cornerRadius = cornerRadius
        self.cardPadding = cardPadding
        self.cellCornerRadiusRatio = cellCornerRadiusRatio
    }
}

public protocol AppTheme: Sendable {
    var id: String { get }
    var displayName: String { get }
    var colors: ThemeColors { get }
    var assets: ThemeAssets { get }
    var board: ThemeBoardStyle { get }
}

// MARK: - Concrete Themes

public struct MeadowTheme: AppTheme {
    public let id: String = "meadow"
    public let displayName: String = "Pradaria Ensolarada"

    public let colors: ThemeColors = ThemeColors(
        sky: Color(hex: "#BFE6F2"),
        ground: Color(hex: "#8CC97A"),
        board: Color(hex: "#B9D89A"),
        boardCell: Color(hex: "#E4F0CF"),
        track: Color(hex: "#C98B55"),
        accent: Color(hex: "#F28FA8")
    )

    public let assets: ThemeAssets = ThemeAssets(
        backgroundImageName: "bg_meadow_game",
        treePropImageName: "prop_tree",
        rockPropImageName: "prop_rock",
        flowerPropImageName: "prop_flower_bush",
        mascotIdleAssetName: "mascot_kitten_idle",
        mascotWalkAssetName: "mascot_kitten_walk",
        mascotCelebrateAssetName: "mascot_kitten_celebrate",
        targetItemAssetName: "prop_yarn_ball"
    )

    public let board: ThemeBoardStyle = ThemeBoardStyle()

    public init() {}
}

public struct WinterTheme: AppTheme {
    public let id: String = "winter"
    public let displayName: String = "Trilha Nevada"

    public let colors: ThemeColors = ThemeColors(
        sky: Color(hex: "#D6E8F7"),
        ground: Color(hex: "#EEF4FA"),
        board: Color(hex: "#CFE0EE"),
        boardCell: Color(hex: "#F7FBFF"),
        track: Color(hex: "#7FA9CF"),
        accent: Color(hex: "#E86F51")
    )

    public let assets: ThemeAssets = ThemeAssets(
        backgroundImageName: "bg_winter_game",
        treePropImageName: "prop_tree_winter",
        rockPropImageName: "prop_rock_winter",
        flowerPropImageName: "prop_flower_winter",
        mascotIdleAssetName: "mascot_kitten_idle",
        mascotWalkAssetName: "mascot_kitten_walk",
        mascotCelebrateAssetName: "mascot_kitten_celebrate",
        targetItemAssetName: "prop_yarn_ball"
    )

    public let board: ThemeBoardStyle = ThemeBoardStyle()

    public init() {}
}

public struct AutumnTheme: AppTheme {
    public let id: String = "autumn"
    public let displayName: String = "Bosque Dourado"

    public let colors: ThemeColors = ThemeColors(
        sky: Color(hex: "#FBE3C2"),
        ground: Color(hex: "#E0A35A"),
        board: Color(hex: "#E9C48F"),
        boardCell: Color(hex: "#FBEBD3"),
        track: Color(hex: "#B5653A"),
        accent: Color(hex: "#D9883A")
    )

    public let assets: ThemeAssets = ThemeAssets(
        backgroundImageName: "bg_autumn_game",
        treePropImageName: "prop_tree_autumn",
        rockPropImageName: "prop_rock_autumn",
        flowerPropImageName: "prop_flower_autumn",
        mascotIdleAssetName: "mascot_kitten_idle",
        mascotWalkAssetName: "mascot_kitten_walk",
        mascotCelebrateAssetName: "mascot_kitten_celebrate",
        targetItemAssetName: "prop_yarn_ball"
    )

    public let board: ThemeBoardStyle = ThemeBoardStyle()

    public init() {}
}

// MARK: - SwiftUI Environment Integration

private struct AppThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: any AppTheme = MeadowTheme()
}

extension EnvironmentValues {
    public var appTheme: any AppTheme {
        get { self[AppThemeEnvironmentKey.self] }
        set { self[AppThemeEnvironmentKey.self] = newValue }
    }
}

extension View {
    public func appTheme(_ theme: any AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
}
