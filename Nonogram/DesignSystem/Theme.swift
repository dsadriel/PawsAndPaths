import SwiftUI

// MARK: - Color Hex Initializer

extension Color {
    public init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexClean.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}

// MARK: - Theme System

public enum Theme {
    
    // MARK: - Spacing & Geometry Tokens
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    public enum CornerRadius {
        public static let sm: CGFloat = 10
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let pill: CGFloat = 999
    }

    public enum LipHeight {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 6
    }

    public static let outlineWidth: CGFloat = 2.0

    // MARK: - Base Palette (Fixed Across All Worlds)
    public enum Colors {
        // Wood
        public static let woodLight = Color(hex: "#D9935C")
        public static let woodBase = Color(hex: "#B86B3C")
        public static let woodDark = Color(hex: "#8A4A26")
        public static let woodOutline = Color(hex: "#6B3518")

        // Cream
        public static let creamSurface = Color(hex: "#FFF6E5")
        public static let creamPanel = Color(hex: "#FBE9C8")
        public static let creamInset = Color(hex: "#F2D8AE")
        public static let creamOutline = Color(hex: "#D9B98A")

        // Ink
        public static let inkPrimary = Color(hex: "#5A3420")
        public static let inkSecondary = Color(hex: "#8C6448")
        public static let inkInverse = Color.white

        // Action Pairs (Face & Lip)
        public struct ActionPair: Sendable {
            public let face: Color
            public let lip: Color
            public let outline: Color

            public init(face: String, lip: String, outline: String? = nil) {
                self.face = Color(hex: face)
                self.lip = Color(hex: lip)
                self.outline = Color(hex: outline ?? lip)
            }
        }

        public static let primaryAction = ActionPair(face: "#7BC74D", lip: "#4E9632")
        public static let secondaryAction = ActionPair(face: "#B87A4F", lip: "#8A542D", outline: "#683B1B")
        public static let dangerAction = ActionPair(face: "#EE6A4E", lip: "#B8442E")
        public static let rewardAction = ActionPair(face: "#F7C548", lip: "#C9922A")
        public static let disabledAction = ActionPair(face: "#C9BFB5", lip: "#9A9087")
        public static let autumnAction = ActionPair(face: "#F5A623", lip: "#D35400")
        public static let winterAction = ActionPair(face: "#5DADE2", lip: "#2E86C1")
    }

    // MARK: - World Palette Tokens
    public struct WorldPalette: Sendable {
        public let sky: Color
        public let ground: Color
        public let board: Color
        public let boardCell: Color
        public let track: Color
        public let accent: Color

        public init(
            sky: String,
            ground: String,
            board: String,
            boardCell: String,
            track: String,
            accent: String
        ) {
            self.sky = Color(hex: sky)
            self.ground = Color(hex: ground)
            self.board = Color(hex: board)
            self.boardCell = Color(hex: boardCell)
            self.track = Color(hex: track)
            self.accent = Color(hex: accent)
        }
    }

    public static let meadowWorld = WorldPalette(
        sky: "#BFE6F2",
        ground: "#8CC97A",
        board: "#B9D89A",
        boardCell: "#E4F0CF",
        track: "#C98B55",
        accent: "#F28FA8"
    )

    public static let winterWorld = WorldPalette(
        sky: "#D6E8F7",
        ground: "#EEF4FA",
        board: "#CFE0EE",
        boardCell: "#F7FBFF",
        track: "#7FA9CF",
        accent: "#E86F51"
    )

    public static let autumnWorld = WorldPalette(
        sky: "#FBE3C2",
        ground: "#E0A35A",
        board: "#E9C48F",
        boardCell: "#FBEBD3",
        track: "#B5653A",
        accent: "#D9883A"
    )

    public static func palette(for chapterTheme: ChapterTheme) -> WorldPalette {
        switch chapterTheme {
        case .meadow:
            return meadowWorld
        case .winter:
            return winterWorld
        case .autumn:
            return autumnWorld
        }
    }

    // MARK: - Typography Tokens
    public enum Typography {
        public static func display() -> Font {
            customOrSystem(name: "Fredoka-Bold", size: 34, weight: .bold)
        }

        public static func title() -> Font {
            customOrSystem(name: "Fredoka-SemiBold", size: 24, weight: .semibold)
        }

        public static func headline() -> Font {
            customOrSystem(name: "Fredoka-SemiBold", size: 18, weight: .semibold)
        }

        public static func clue(size: CGFloat = 16) -> Font {
            customOrSystem(name: "Fredoka-SemiBold", size: size, weight: .semibold).monospacedDigit()
        }

        public static func body() -> Font {
            customOrSystem(name: "Nunito-SemiBold", size: 16, weight: .semibold)
        }

        public static func caption() -> Font {
            customOrSystem(name: "Nunito-Bold", size: 13, weight: .bold)
        }

        private static func customOrSystem(name: String, size: CGFloat, weight: Font.Weight) -> Font {
            if UIFont(name: name, size: size) != nil {
                return Font.custom(name, size: size)
            }
            return Font.system(size: size, weight: weight, design: .rounded)
        }
    }
}

// MARK: - UI Components

/// Chunky 3D-feel button with solid lip, top gloss highlight, and spring press action.
public struct ChunkyButtonStyle: ButtonStyle {
    public let actionPair: Theme.Colors.ActionPair
    public let lipHeight: CGFloat
    public let cornerRadius: CGFloat
    public let horizontalPadding: CGFloat
    public let verticalPadding: CGFloat

    public init(
        actionPair: Theme.Colors.ActionPair = Theme.Colors.primaryAction,
        lipHeight: CGFloat = Theme.LipHeight.md,
        cornerRadius: CGFloat = Theme.CornerRadius.md,
        horizontalPadding: CGFloat = Theme.Spacing.lg,
        verticalPadding: CGFloat = Theme.Spacing.sm
    ) {
        self.actionPair = actionPair
        self.lipHeight = lipHeight
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let currentLip = isPressed ? 1.0 : lipHeight
        let verticalOffset = isPressed ? (lipHeight - 1.0) : 0.0

        configuration.label
            .font(Theme.Typography.headline())
            .foregroundColor(Theme.Colors.inkInverse)
            .shadow(color: actionPair.lip.opacity(0.8), radius: 0, x: 0, y: 1.5)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        // Lip foundation
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(actionPair.lip)
                            .frame(height: geo.size.height + currentLip)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(actionPair.outline, lineWidth: Theme.outlineWidth)
                            )

                        // Button Face
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(actionPair.face)
                            .frame(height: geo.size.height)
                            .offset(y: -currentLip)
                            .overlay(
                                // Inner top highlight
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                                    .offset(y: -currentLip)
                                    .mask(
                                        VStack {
                                            LinearGradient(
                                                colors: [.white, .clear],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                            .frame(height: geo.size.height / 2)
                                            Spacer()
                                        }
                                        .offset(y: -currentLip)
                                    )
                            )
                    }
                }
            )
            .offset(y: verticalOffset)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
    }
}

/// Circular chunky button with solid lip and spring press action, ideal for icon buttons.
public struct ChunkyCircleButtonStyle: ButtonStyle {
    public let actionPair: Theme.Colors.ActionPair
    public let diameter: CGFloat
    public let lipHeight: CGFloat

    public init(
        actionPair: Theme.Colors.ActionPair = Theme.Colors.secondaryAction,
        diameter: CGFloat = 44,
        lipHeight: CGFloat = Theme.LipHeight.sm
    ) {
        self.actionPair = actionPair
        self.diameter = diameter
        self.lipHeight = lipHeight
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let currentLip = isPressed ? 1.0 : lipHeight
        let verticalOffset = isPressed ? (lipHeight - 1.0) : 0.0

        configuration.label
            .font(.system(size: diameter * 0.42, weight: .bold, design: .rounded))
            .foregroundColor(Theme.Colors.inkInverse)
            .frame(width: diameter, height: diameter)
            .background(
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(actionPair.lip)
                        .frame(width: diameter, height: diameter)
                        .offset(y: currentLip)
                        .overlay(
                            Circle()
                                .stroke(actionPair.outline, lineWidth: Theme.outlineWidth)
                                .offset(y: currentLip)
                        )

                    Circle()
                        .fill(actionPair.face)
                        .frame(width: diameter, height: diameter)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                        )
                }
            )
            .offset(y: verticalOffset)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isPressed)
    }
}

/// Cozy wood framed panel with bottom lip, cream content surface, and optional ribbon header.
public struct WoodPanel<Content: View>: View {
    public let title: String?
    public let content: Content

    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let title = title {
                // Header Ribbon
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.woodLight)

                    Text(title)
                        .font(Theme.Typography.title())
                        .foregroundColor(Theme.Colors.creamSurface)
                        .shadow(color: Theme.Colors.woodDark, radius: 0, x: 0, y: 1.5)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.woodLight)
                        .scaleEffect(x: -1, y: 1)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.woodBase)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(Theme.Colors.woodOutline, lineWidth: Theme.outlineWidth)
                        )
                )
                .offset(y: Theme.Spacing.xs)
                .zIndex(2)
            }

            // Panel Body: content defines size, hugs inner cream and outer wood frame
            content
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.creamSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Theme.Colors.creamOutline, lineWidth: 1.5)
                        )
                )
                .padding(Theme.Spacing.sm)
                .background(
                    ZStack(alignment: .bottom) {
                        // Wood bottom lip
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(Theme.Colors.woodDark)
                            .offset(y: Theme.LipHeight.md)

                        // Wood face
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(Theme.Colors.woodBase)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                    .stroke(Theme.Colors.woodOutline, lineWidth: Theme.outlineWidth)
                            )
                    }
                )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Cream card container for grouped items within a modal or screen.
public struct CreamCard<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.creamPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.creamOutline, lineWidth: 1.5)
                    )
            )
    }
}

/// Pill container for coins, hearts, seeds, or stars with an illustrated icon.
public struct CounterPill: View {
    public let iconAssetName: String?
    public let iconSystemName: String?
    public let iconSize: CGFloat
    public let value: String
    public let iconColor: Color
    public let onPlusTapped: (() -> Void)?

    public init(
        iconAssetName: String? = nil,
        iconSystemName: String? = nil,
        iconColor: Color = Theme.Colors.rewardAction.face,
        iconSize: CGFloat = 24,
        value: String,
        onPlusTapped: (() -> Void)? = nil
    ) {
        self.iconAssetName = iconAssetName
        self.iconSystemName = iconSystemName
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.value = value
        self.onPlusTapped = onPlusTapped
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let assetName = iconAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            } else if let systemName = iconSystemName {
                Image(systemName: systemName)
                    .font(.system(size: iconSize * 0.65, weight: .bold))
                    .foregroundColor(iconColor)
                    .frame(width: iconSize, height: iconSize)
            }

            Text(value)
                .font(Theme.Typography.headline())
                .foregroundColor(Theme.Colors.inkPrimary)

            if let onPlus = onPlusTapped {
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Theme.Colors.primaryAction.face))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.creamSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.creamOutline, lineWidth: 1.5)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
