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

/// Main scrolling campaign progression map supporting infinite progression in batches of 20.
public struct CampaignMapView: View {
    @StateObject private var progressManager = CampaignProgressManager.shared
    @State private var activeGameLevel: CampaignLevel? = nil

    @State private var isCurrentLevelOffScreen: Bool = false
    @State private var currentLevelIsAbove: Bool = false

    private let nodeSpacingY: CGFloat = 125
    private let topPadding: CGFloat = 90
    private let bottomPadding: CGFloat = 140

    public init() {}

    private var currentLevel: CampaignLevel {
        levels.first(where: { $0.id == progressManager.unlockedLevelIndex }) ?? levels[0]
    }

    private var currentTheme: ChapterTheme {
        currentLevel.theme
    }

    private var currentActionPair: Theme.Colors.ActionPair {
        switch currentTheme {
        case .meadow:
            return Theme.Colors.primaryAction
        case .autumn:
            return Theme.Colors.autumnAction
        case .winter:
            return Theme.Colors.winterAction
        }
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
                                    // Dynamic Continuous Biome Terrain per 20 levels
                                    biomeTerrainBackground(totalHeight: totalHeight, width: screenWidth)

                                    // Background Scenery Decorations matching each chapter biome
                                    sceneryDecorations(points: points, width: screenWidth)

                                    // The Winding Dirt Road connecting all nodes with thematic coloring
                                    StyledWindingRoadView(points: points)

                                    // Chapter Gateway Milestone markers along the trail (rendered above the road)
                                    chapterMilestones(points: points, width: screenWidth)

                                    // Reliable scroll target anchors at exact waypoint coordinates
                                    ForEach(levels.indices, id: \.self) { idx in
                                        let lvl = levels[idx]
                                        if idx < points.count {
                                            Color.clear
                                                .frame(width: 44, height: 44)
                                                .alignmentGuide(.leading) { _ in -(points[idx].x - 22) }
                                                .alignmentGuide(.top) { _ in -(points[idx].y - 22) }
                                                .id("anchor_\(lvl.id)")
                                        }
                                    }

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
                                scrollToCurrent(proxy: proxy, animated: false)
                            }

                            // Floating Bottom Navigation: [Ir para Fase X] [Jogar Fase X]
                            bottomFloatingBar(proxy: proxy)
                        }
                    }

                    // Floating Top Status Bar & Next Theme Preview Banner
                    VStack(spacing: 6) {
                        topStatusBar
                        nextThemePreviewBanner
                    }
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
            .fullScreenCover(item: $activeGameLevel) { level in
                GameView(campaignLevel: level) {
                    activeGameLevel = nil
                }
                .appTheme(level.theme.appTheme)
            }
        }
    }

    private func scrollToCurrent(proxy: ScrollViewProxy, animated: Bool = false) {
        let targetId = progressManager.unlockedLevelIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if animated {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    proxy.scrollTo("anchor_\(targetId)", anchor: .center)
                }
            } else {
                proxy.scrollTo("anchor_\(targetId)", anchor: .center)
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
                Button {
                    HapticManager.shared.tapSelection()
                    scrollToCurrent(proxy: proxy, animated: true)
                } label: {
                    Image(systemName: isCurrentLevelOffScreen ? (currentLevelIsAbove ? "arrow.up" : "arrow.down") : "pawprint.fill")
                        .font(.system(size: 18, weight: .black))
                }
                .buttonStyle(ChunkyCircleButtonStyle(actionPair: Theme.Colors.secondaryAction, diameter: 46))
                .shadow(color: Theme.Colors.woodDark.opacity(0.18), radius: 6, x: 0, y: 3)
            }
            .padding(.trailing, Theme.Spacing.md)

            // Persistent Prominent Play Button
            Button {
                HapticManager.shared.buttonPress()
                SoundManager.shared.buttonPress()
                activeGameLevel = currentLevel
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .heavy))
                    Text("Jogar Fase \(currentLevel.id)")
                        .font(Theme.Typography.headline())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                ChunkyButtonStyle(
                    actionPair: currentActionPair,
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

    // MARK: - Top Status Bar with Coins (Minimalist 2-Pill Design)
    private var topStatusBar: some View {
        let appTheme = currentTheme.appTheme
        return HStack(alignment: .center) {
            // Mascot and Game Title / Current Phase
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

            // Total Coins Counter Pill (Single clean background)
            CounterPill(
                iconAssetName: "icon_seed_coin",
                iconSize: 22,
                value: "\(progressManager.coins)"
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xxs)
    }

    // MARK: - Next Theme Preview Banner (Floating below top status bar)
    private var nextThemePreviewBanner: some View {
        let currentUnlocked = progressManager.unlockedLevelIndex
        let currentChapter = (max(1, currentUnlocked) - 1) / 20
        let nextChapterStart = (currentChapter + 1) * 20 + 1
        let nextTheme = ChapterTheme.theme(for: nextChapterStart)

        return HStack(spacing: 7) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.Colors.woodLight)

            Image(systemName: nextTheme.systemIcon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.Colors.woodDark)

            HStack(spacing: 4) {
                Text("Próximo:")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.Colors.inkSecondary)

                Text(nextTheme.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.inkPrimary)

                Text("•")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.Colors.inkSecondary.opacity(0.5))

                Text("Fase \(nextChapterStart)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.Colors.woodDark)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Theme.Colors.creamSurface.opacity(0.95))
                .overlay(
                    Capsule().stroke(Theme.Colors.creamOutline, lineWidth: 1.2)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.12), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - Biome Terrain Gradient Background with Grass Texture (Living World per 20 levels)
    private func biomeTerrainBackground(totalHeight: CGFloat, width: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                stops: biomeTerrainStops(count: levels.count),
                startPoint: .top,
                endPoint: .bottom
            )

            Image("texture_grass_pattern")
                .resizable(resizingMode: .tile)
                .opacity(0.22)
                .blendMode(.multiply)
        }
        .frame(width: width, height: totalHeight)
    }

    private func biomeTerrainStops(count: Int) -> [Gradient.Stop] {
        guard count > 0 else {
            return [Gradient.Stop(color: MeadowTheme().colors.ground, location: 0)]
        }
        let totalLevels = CGFloat(count)
        var stops: [Gradient.Stop] = []

        let chapters = max(1, Int(ceil(Double(count) / 20.0)))
        for ch in 0..<chapters {
            let startLvl = ch * 20 + 1
            let theme = ChapterTheme.theme(for: startLvl)
            let groundColor = theme.appTheme.colors.ground

            // Level 1 is at bottom (location 1.0), highest level is at top (location 0.0)
            let topFraction = max(0.0, 1.0 - CGFloat((ch + 1) * 20) / totalLevels)
            let bottomFraction = min(1.0, 1.0 - CGFloat(ch * 20) / totalLevels)
            let midFraction = (topFraction + bottomFraction) / 2

            stops.append(Gradient.Stop(color: groundColor.opacity(0.85), location: topFraction + 0.02))
            stops.append(Gradient.Stop(color: groundColor, location: midFraction))
            stops.append(Gradient.Stop(color: groundColor.opacity(0.85), location: bottomFraction - 0.02))
        }

        stops.sort { $0.location < $1.location }
        return stops
    }

    // MARK: - Chapter Gateway Milestones (Prominent full-width regional boundary gateway)
    @ViewBuilder
    private func chapterMilestones(points: [CGPoint], width: CGFloat) -> some View {
        ForEach(levels.indices, id: \.self) { idx in
            let lvl = levels[idx]
            if (lvl.id - 1) % 20 == 0 && idx < points.count {
                let pt = points[idx]
                let chTitle = ChapterTheme.chapterTitle(for: lvl.id)
                let chNum = ChapterTheme.chapterNumber(for: lvl.id)
                let icon = lvl.theme.systemIcon
                let theme = lvl.theme

                fullWidthChapterGateway(
                    chapterNumber: chNum,
                    title: chTitle,
                    icon: icon,
                    theme: theme,
                    width: width
                )
                .position(x: width / 2, y: pt.y + 68)
            }
        }
    }

    private func fullWidthChapterGateway(
        chapterNumber: Int,
        title: String,
        icon: String,
        theme: ChapterTheme,
        width: CGFloat
    ) -> some View {
        ZStack(alignment: .center) {
            // Full-width rustic wooden border boundary rails spanning edge to edge
            VStack(spacing: 7) {
                // Top boundary fence beam
                Rectangle()
                    .fill(Theme.Colors.woodBase)
                    .frame(height: 6)
                    .overlay(
                        Rectangle().stroke(Theme.Colors.woodOutline, lineWidth: 1)
                    )

                // Bottom boundary fence beam
                Rectangle()
                    .fill(Theme.Colors.woodDark)
                    .frame(height: 5)
                    .overlay(
                        Rectangle().stroke(Theme.Colors.woodOutline, lineWidth: 1)
                    )
            }
            .frame(width: width)
            .shadow(color: Theme.Colors.woodDark.opacity(0.35), radius: 4, x: 0, y: 3)

            // Boundary posts on the left and right screen borders
            HStack {
                boundaryPost
                Spacer()
                boundaryPost
            }
            .frame(width: width - 8)

            // Prominent Carved Wooden Plaque in Center
            VStack(spacing: 2) {
                Text("✦  CAPÍTULO \(chapterNumber)  ✦")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Colors.woodLight)
                    .tracking(1.2)

                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(Theme.Colors.woodLight)

                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.Colors.creamSurface)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.woodBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.woodOutline, lineWidth: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md - 2)
                            .stroke(Theme.Colors.woodLight.opacity(0.4), lineWidth: 1)
                            .padding(2)
                    )
                    .shadow(color: Theme.Colors.woodDark.opacity(0.45), radius: 8, x: 0, y: 5)
            )
        }
        .frame(width: width, height: 64)
    }

    private var boundaryPost: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Theme.Colors.woodDark)
            .frame(width: 14, height: 32)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Theme.Colors.woodOutline, lineWidth: 1.5)
            )
            .overlay(
                Circle()
                    .fill(Theme.Colors.woodLight)
                    .frame(width: 6, height: 6)
                    .offset(y: -8)
            )
            .shadow(color: Theme.Colors.woodDark.opacity(0.3), radius: 3, x: 0, y: 2)
    }

    // MARK: - Scenery Decorations per Chapter Biome
    @ViewBuilder
    private func sceneryDecorations(points: [CGPoint], width: CGFloat) -> some View {
        ForEach(0..<points.count, id: \.self) { i in
            let pt = points[i]
            let lvl = levels[i]
            let levelTheme = lvl.theme
            let appTheme = levelTheme.appTheme
            let onLeft = pt.x > width / 2
            let decorX = onLeft ? width * 0.16 : width * 0.84
            let decorY = pt.y + 15

            if i % 3 == 0, let tree = appTheme.assets.treePropImageName {
                treeDecoration(name: tree)
                    .position(x: decorX, y: decorY)
            } else if i % 3 == 1, let rock = appTheme.assets.rockPropImageName {
                rockDecoration(name: rock)
                    .position(x: decorX, y: decorY)
            } else if let flower = appTheme.assets.flowerPropImageName {
                flowerDecoration(name: flower)
                    .position(x: decorX, y: decorY)
            }
        }
    }

    @ViewBuilder
    private func treeDecoration(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .opacity(0.95)
    }

    @ViewBuilder
    private func rockDecoration(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .opacity(0.9)
    }

    @ViewBuilder
    private func flowerDecoration(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .opacity(0.95)
    }
}
