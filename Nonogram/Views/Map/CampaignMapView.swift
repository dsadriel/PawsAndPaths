import SwiftUI

/// PreferenceKey to track current level node's position relative to the scroll viewport.
struct CurrentLevelFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

/// Custom layout placing each child at its calculated waypoint coordinate in layout space,
/// allowing ScrollViewProxy.scrollTo to accurately center any node.
struct WindingMapLayout: Layout {
    let points: [CGPoint]
    let totalHeight: CGFloat
    let width: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, subview) in subviews.enumerated() {
            guard index < points.count else { continue }
            let pt = points[index]
            let size = subview.sizeThatFits(.unspecified)
            subview.place(
                at: CGPoint(x: bounds.minX + pt.x - size.width / 2, y: bounds.minY + pt.y - size.height / 2),
                proposal: ProposedViewSize(size)
            )
        }
    }
}

/// Main scrolling campaign progression map supporting infinite progression in batches of 15.
public struct CampaignMapView: View {
    @StateObject private var progressManager = CampaignProgressManager.shared
    @AppStorage("selected_campaign_theme") private var selectedThemeRaw: String = ChapterTheme.meadow.rawValue

    @State private var activeGameLevel: CampaignLevel? = nil
    @State private var isShowingThemePicker: Bool = false

    @State private var isCurrentLevelOffScreen: Bool = false
    @State private var currentLevelIsAbove: Bool = false

    private let nodeSpacingY: CGFloat = 125
    private let topPadding: CGFloat = 90
    private let bottomPadding: CGFloat = 140

    public init() {}

    private var currentTheme: ChapterTheme {
        ChapterTheme(rawValue: selectedThemeRaw) ?? .meadow
    }

    private var levels: [CampaignLevel] {
        CampaignLevelGenerator.levelsForProgress(unlockedLevelIndex: progressManager.unlockedLevelIndex)
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                let totalHeight = CGFloat(levels.count) * nodeSpacingY + topPadding + bottomPadding
                let points = computeWaypoints(width: screenWidth, totalHeight: totalHeight)
                let appTheme = currentTheme.appTheme

                ZStack(alignment: .top) {
                    // Scenic gradient background matching selected theme
                    LinearGradient(
                        colors: [
                            appTheme.colors.sky.opacity(0.85),
                            appTheme.colors.ground.opacity(0.60),
                            appTheme.colors.ground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    ScrollViewReader { proxy in
                        ZStack(alignment: .bottom) {
                            ScrollView(.vertical, showsIndicators: false) {
                                ZStack(alignment: .topLeading) {
                                    // Background Scenery Decorations
                                    sceneryDecorations(points: points, width: screenWidth)

                                    // The Winding Dirt Road connecting all nodes
                                    StyledWindingRoadView(points: points)

                                    // Level Stepping-Stone Nodes placed in layout coordinate space
                                    WindingMapLayout(points: points, totalHeight: totalHeight, width: screenWidth) {
                                        ForEach(levels) { level in
                                            let isUnlocked = progressManager.isUnlocked(id: level.id)
                                            let isCompleted = progressManager.isCompleted(id: level.id)
                                            let isCurrent = level.id == progressManager.unlockedLevelIndex

                                            LevelNodeView(
                                                level: level,
                                                isUnlocked: isUnlocked,
                                                isCompleted: isCompleted,
                                                isCurrent: isCurrent,
                                                onTap: {
                                                    if isUnlocked {
                                                        activeGameLevel = level
                                                    }
                                                }
                                            )
                                            .id(level.id)
                                            .background(
                                                Group {
                                                    if isCurrent {
                                                        GeometryReader { nodeGeo in
                                                            Color.clear.preference(
                                                                key: CurrentLevelFramePreferenceKey.self,
                                                                value: nodeGeo.frame(in: .named("mapScrollArea"))
                                                            )
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                                .frame(width: screenWidth, height: totalHeight)
                            }
                            .coordinateSpace(name: "mapScrollArea")
                            .onAppear {
                                scrollToCurrent(proxy: proxy)
                            }

                            // Floating Bottom Navigation: [Ir para Fase X] [Jogar Fase X]
                            bottomFloatingBar(proxy: proxy)
                        }
                    }

                    // Floating Top Status Bar with Theme Selector
                    topStatusBar
                }
                .onPreferenceChange(CurrentLevelFramePreferenceKey.self) { frame in
                    guard frame != .zero else { return }
                    let topCutoff: CGFloat = topPadding + 20
                    let bottomCutoff: CGFloat = screenHeight - bottomPadding
                    let offScreen = frame.maxY < topCutoff || frame.minY > bottomCutoff
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        self.isCurrentLevelOffScreen = offScreen
                        self.currentLevelIsAbove = frame.midY < topCutoff
                    }
                }
            }
            .navigationBarHidden(true)
            .appTheme(currentTheme.appTheme)
            .sheet(isPresented: $isShowingThemePicker) {
                themePickerSheet
            }
            .fullScreenCover(item: $activeGameLevel) { level in
                GameView(campaignLevel: level) {
                    activeGameLevel = nil
                }
                .appTheme(currentTheme.appTheme)
            }
        }
    }

    private func scrollToCurrent(proxy: ScrollViewProxy) {
        let targetId = progressManager.unlockedLevelIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                proxy.scrollTo(targetId, anchor: .center)
            }
        }
    }

    // MARK: - Bottom Floating Bar: Play Button + Icon-only Jump Button above it on the bottom-right
    private func bottomFloatingBar(proxy: ScrollViewProxy) -> some View {
        let currentLevel = levels.first(where: { $0.id == progressManager.unlockedLevelIndex }) ?? levels[0]

        return VStack(spacing: Theme.Spacing.xs) {
            // Icon-only jump button placed on bottom-right, above the play button
            HStack {
                Spacer()
                if isCurrentLevelOffScreen {
                    Button {
                        HapticManager.shared.tapSelection()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            proxy.scrollTo(progressManager.unlockedLevelIndex, anchor: .center)
                        }
                    } label: {
                        Image(systemName: currentLevelIsAbove ? "arrow.up" : "arrow.down")
                            .font(.system(size: 18, weight: .black))
                    }
                    .buttonStyle(ChunkyCircleButtonStyle(actionPair: Theme.Colors.rewardAction, diameter: 46))
                    .shadow(color: Theme.Colors.woodDark.opacity(0.18), radius: 6, x: 0, y: 3)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .padding(.trailing, Theme.Spacing.md)

            // Persistent Prominent Play Button
            Button {
                HapticManager.shared.buttonPress()
                activeGameLevel = currentLevel
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .heavy))
                    Text("Jogar Fase \(currentLevel.id)")
                        .font(Theme.Typography.headline())
                    Image(currentTheme.appTheme.assets.mascotIdleAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                ChunkyButtonStyle(
                    actionPair: Theme.Colors.primaryAction,
                    lipHeight: Theme.LipHeight.md,
                    cornerRadius: Theme.CornerRadius.pill,
                    horizontalPadding: Theme.Spacing.lg,
                    verticalPadding: Theme.Spacing.md
                )
            )
            .padding(.horizontal, Theme.Spacing.md)
            .shadow(color: Theme.Colors.woodDark.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .padding(.bottom, Theme.Spacing.md)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isCurrentLevelOffScreen)
    }

    // MARK: - Waypoint Calculations (Going UP from Bottom)
    private func computeWaypoints(width: CGFloat, totalHeight: CGFloat) -> [CGPoint] {
        let centerX = width / 2
        let amplitude = max(60, min(110, (width - 150) / 2))

        return levels.enumerated().map { index, _ in
            let angle = Double(index) * 0.95
            let x = centerX + sin(angle) * amplitude
            let y = totalHeight - bottomPadding - CGFloat(index) * nodeSpacingY
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Top Status Bar with Theme Selector Button & Coins
    private var topStatusBar: some View {
        let appTheme = currentTheme.appTheme
        return HStack(alignment: .center, spacing: Theme.Spacing.sm) {
            // Mascot and Game Title
            HStack(spacing: Theme.Spacing.xs) {
                Image(appTheme.assets.mascotIdleAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Paws & Paths")
                        .font(Theme.Typography.headline())
                        .foregroundColor(Theme.Colors.inkPrimary)
                    Text("Fase \(progressManager.unlockedLevelIndex)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.inkSecondary)
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

            Spacer()

            // Theme Switcher Button
            Button {
                HapticManager.shared.tapSelection()
                isShowingThemePicker = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.woodDark)
                    Text(currentTheme.title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.inkPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
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
            .buttonStyle(PlainButtonStyle())

            // Total Coins Counter Pill
            CounterPill(
                iconAssetName: "icon_seed_coin",
                iconSize: 22,
                value: "\(progressManager.coins)"
            )
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
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.xs)
    }

    // MARK: - Theme Picker Sheet
    private var themePickerSheet: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                Text("Escolha a estética do mundo e do tabuleiro:")
                    .font(Theme.Typography.caption())
                    .foregroundColor(Theme.Colors.inkSecondary)
                    .padding(.top, Theme.Spacing.xs)

                ForEach(ChapterTheme.allCases) { theme in
                    let isSelected = theme == currentTheme
                    Button {
                        HapticManager.shared.tapSelection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedThemeRaw = theme.rawValue
                        }
                        isShowingThemePicker = false
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            // Theme Color Palette Swatch
                            ZStack {
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .fill(theme.appTheme.colors.ground)
                                    .frame(width: 44, height: 44)

                                Image(systemName: theme.systemIcon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.title)
                                    .font(Theme.Typography.headline())
                                    .foregroundColor(Theme.Colors.inkPrimary)
                                Text(theme.appTheme.displayName)
                                    .font(Theme.Typography.caption())
                                    .foregroundColor(Theme.Colors.inkSecondary)
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Theme.Colors.primaryAction.face)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                .fill(isSelected ? Theme.Colors.creamSurface : Theme.Colors.creamPanel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                                        .stroke(isSelected ? Theme.Colors.primaryAction.face : Theme.Colors.creamOutline, lineWidth: isSelected ? 2 : 1)
                                )
                                .shadow(color: Theme.Colors.woodDark.opacity(0.06), radius: 4, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.creamInset.ignoresSafeArea())
            .navigationTitle("Temas do Jogo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        isShowingThemePicker = false
                    }
                    .foregroundColor(Theme.Colors.woodDark)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Scenery Decorations
    @ViewBuilder
    private func sceneryDecorations(points: [CGPoint], width: CGFloat) -> some View {
        let appTheme = currentTheme.appTheme
        ForEach(0..<points.count, id: \.self) { i in
            let pt = points[i]
            let onLeft = pt.x > width / 2
            let decorX = onLeft ? width * 0.16 : width * 0.84
            let decorY = pt.y + 15

            if i % 3 == 0, let tree = appTheme.assets.treePropImageName {
                Image(tree)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .position(x: decorX, y: decorY)
                    .opacity(0.95)
            } else if i % 3 == 1, let rock = appTheme.assets.rockPropImageName {
                Image(rock)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .position(x: decorX, y: decorY)
                    .opacity(0.9)
            } else if let flower = appTheme.assets.flowerPropImageName {
                Image(flower)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .position(x: decorX, y: decorY)
                    .opacity(0.95)
            }
        }
    }
}
