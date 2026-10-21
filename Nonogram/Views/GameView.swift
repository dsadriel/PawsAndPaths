import SwiftUI

public struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var fallbackAppTheme
    @StateObject private var viewModel: NonogramGameViewModel
    @ObservedObject private var progressManager = CampaignProgressManager.shared

    private var levelTheme: ChapterTheme {
        viewModel.campaignLevel?.theme ?? .meadow
    }

    private var appTheme: any AppTheme {
        levelTheme.appTheme
    }

    private var activeActionPair: Theme.Colors.ActionPair {
        switch levelTheme {
        case .meadow:
            return Theme.Colors.primaryAction
        case .autumn:
            return Theme.Colors.autumnAction
        case .winter:
            return Theme.Colors.winterAction
        }
    }

    private var backgroundMultiply: Color {
        .white
    }

    private var backgroundOverlay: Color {
        Color.black.opacity(0.03)
    }

    @State private var animatedCoinsBounced: Bool = false
    @State private var showingHintOverlay: Bool = false
    @State private var showingInsufficientCoinsOverlay: Bool = false
    @State private var showingRewardModal: Bool = false
    @State private var rewardProgress: CGFloat = 0.0
    @State private var rewardClaimed: Bool = false
    @State private var showingResetConfirmationAlert: Bool = false
    @State private var isDraggingActive: Bool = false
    private var onDismiss: (() -> Void)?

    public enum InitialOverlayState {
        case none, hint, insufficientCoins, victory
    }

    public init(campaignLevel: CampaignLevel? = nil, initialOverlay: InitialOverlayState = .none, onDismiss: (() -> Void)? = nil) {
        let vm = NonogramGameViewModel(campaignLevel: campaignLevel)
        if initialOverlay == .victory {
            vm.setSimulatedVictoryState()
        }
        _viewModel = StateObject(wrappedValue: vm)
        self.onDismiss = onDismiss
        _showingHintOverlay = State(initialValue: initialOverlay == .hint)
        _showingInsufficientCoinsOverlay = State(initialValue: initialOverlay == .insufficientCoins)
    }

    public var body: some View {
        GeometryReader { screenGeo in
            ZStack {
                // Illustrated theme background ambiance - constrained strictly to screen size
                Group {
                    if let bgName = appTheme.assets.backgroundImageName {
                        Image(bgName)
                            .resizable()
                            .scaledToFill()
                            .colorMultiply(backgroundMultiply)
                            .clipped()
                            .overlay(backgroundOverlay)
                    } else {
                        LinearGradient(
                            colors: [appTheme.colors.sky.opacity(0.4), appTheme.colors.ground.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top clean navigation header: "Fase X" (bold) and subtitle below
                    cleanHeaderView
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)

                    Spacer(minLength: Theme.Spacing.xs)

                    // Grid expands horizontally with clear card separation
                    boardContainerView
                        .padding(.horizontal, Theme.Spacing.md)

                    Spacer(minLength: Theme.Spacing.xs)

                    // Bottom controls: Hidden smoothly when puzzle is solved, keeping height fixed so grid doesn't move
                    bottomControlsView
                        .padding(.bottom, Theme.Spacing.md)
                        .opacity(viewModel.isSolved ? 0 : 1)
                        .disabled(viewModel.isSolved)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.isSolved)
                }
                .frame(width: screenGeo.size.width, height: screenGeo.size.height)

                // Fast-forward hold overlay (ONLY active during reveal animation before celebration modal)
                if viewModel.isSolved && !viewModel.isCompletedCelebration {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewModel.isHoldingScreen = true
                                }
                                .onEnded { _ in
                                    viewModel.isHoldingScreen = false
                                }
                        )
                }

                // Victory Modal Overlay
                if viewModel.isCompletedCelebration {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    victoryOverlayView
                        .padding(.horizontal, Theme.Spacing.lg)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                // Simulated Rewarded Video Ad Modal
                if showingRewardModal {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    rewardedVideoModalView
                        .padding(.horizontal, Theme.Spacing.lg)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                // Hint Confirmation Modal Overlay
                if showingHintOverlay {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                showingHintOverlay = false
                            }
                        }

                    hintConfirmationModalView
                        .padding(.horizontal, Theme.Spacing.lg)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                // Insufficient Coins Modal Overlay
                if showingInsufficientCoinsOverlay {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                showingInsufficientCoinsOverlay = false
                            }
                        }

                    insufficientCoinsModalView
                        .padding(.horizontal, Theme.Spacing.lg)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .frame(width: screenGeo.size.width, height: screenGeo.size.height)
        }
        .appTheme(appTheme)
        .navigationBarHidden(true)
        .alert("Reiniciar Fase?", isPresented: $showingResetConfirmationAlert) {
            Button("Reiniciar", role: .destructive) {
                withAnimation {
                    viewModel.resetCurrentLevel()
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Todo o seu progresso nesta fase será apagado.")
        }
        .onDisappear {
            viewModel.persistCurrentProgressIfNeeded()
        }
        .onChange(of: viewModel.isCompletedCelebration) { isCelebrating in
            if isCelebrating {
                animatedCoinsBounced = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                        animatedCoinsBounced = true
                    }
                    HapticManager.shared.rewardCollected()
                }
            }
        }
    }

    // MARK: - Clean Header: "Fase X, Subtítulo" (Action buttons hide on completion)
    private var cleanHeaderView: some View {
        HStack {
            if !viewModel.isSolved {
                Button {
                    onDismiss?()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                }
                .buttonStyle(ChunkyCircleButtonStyle(actionPair: Theme.Colors.secondaryAction, diameter: 40))
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(width: 40)
            }

            Spacer()

            // Header Title: "Fase X" (bold), subtitle below (Unified geometry with CounterPill)
            VStack(spacing: 1) {
                Text("Fase \(viewModel.campaignLevel?.id ?? 1)")
                    .font(Theme.Typography.headline())
                    .fontWeight(.heavy)
                    .foregroundColor(Theme.Colors.inkPrimary)

                Text(viewModel.campaignLevel?.subtitle ?? levelTheme.title)
                    .font(Theme.Typography.caption())
                    .foregroundColor(Theme.Colors.inkSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 6)
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

            if !viewModel.isSolved {
                // Total Coins Counter Pill with clean single background
                CounterPill(
                    iconAssetName: "icon_seed_coin",
                    iconSize: 22,
                    value: "\(progressManager.coins)"
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(width: 40)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.isSolved)
    }

    // MARK: - Board Container
    private var boardContainerView: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 24
            let availableHeight = geometry.size.height - 16

            let maxRowClueCount = viewModel.level.rowClues.map(\.count).max() ?? 1
            let maxColClueCount = viewModel.level.colClues.map(\.count).max() ?? 1

            let spacing: CGFloat = 3
            let rowClueWidth: CGFloat = max(42, CGFloat(maxRowClueCount) * 18 + 12)
            let colClueHeight: CGFloat = max(38, CGFloat(maxColClueCount) * 18 + 10)

            let cols = CGFloat(viewModel.level.cols)
            let rows = CGFloat(viewModel.level.rows)

            let maxCellWidth = (availableWidth - rowClueWidth - (cols - 1) * spacing - 12) / cols
            let maxCellHeight = (availableHeight - colClueHeight - (rows - 1) * spacing - 12) / rows
            let cellSize = min(maxCellWidth, maxCellHeight)

            let totalBoardWidth = rowClueWidth + cols * cellSize + (cols - 1) * spacing
            let totalBoardHeight = colClueHeight + rows * cellSize + (rows - 1) * spacing

            VStack {
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 0) {
                        // Top Column Clues
                        HStack(spacing: 0) {
                            Color.clear
                                .frame(width: rowClueWidth, height: colClueHeight)

                            HStack(spacing: spacing) {
                                ForEach(0..<viewModel.level.cols, id: \.self) { c in
                                    ColumnClueView(
                                        clues: viewModel.level.colClues[c],
                                        isSatisfied: c < viewModel.colSatisfaction.count ? viewModel.colSatisfaction[c] : false,
                                        cellSize: cellSize
                                    )
                                }
                            }
                        }

                        // Left Row Clues + Interactive Grid
                        HStack(alignment: .top, spacing: 0) {
                            VStack(spacing: spacing) {
                                ForEach(0..<viewModel.level.rows, id: \.self) { r in
                                    RowClueView(
                                        clues: viewModel.level.rowClues[r],
                                        isSatisfied: r < viewModel.rowSatisfaction.count ? viewModel.rowSatisfaction[r] : false,
                                        cellSize: cellSize
                                    )
                                }
                            }
                            .frame(width: rowClueWidth)

                            // Interactive Grid with floating mascot animation overlay
                            gridGestureArea(cellSize: cellSize, spacing: spacing)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: appTheme.board.cornerRadius)
                            .fill(Theme.Colors.creamSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: appTheme.board.cornerRadius)
                                    .stroke(Theme.Colors.creamOutline, lineWidth: 2)
                            )
                            .shadow(color: Theme.Colors.woodDark.opacity(0.12), radius: 8, x: 0, y: 4)
                    )
                    .frame(width: totalBoardWidth + 16, height: totalBoardHeight + 16)

                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Grid Gesture Area with Smooth Floating Mascot Animation
    private func gridGestureArea(cellSize: CGFloat, spacing: CGFloat) -> some View {
        let rows = viewModel.level.rows
        let cols = viewModel.level.cols

        return ZStack(alignment: .topLeading) {
            // Grid tiles
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { c in
                            let pos = GridPosition(row: r, col: c)
                            CellView(
                                state: viewModel.grid[r][c],
                                pos: pos,
                                isStart: pos == viewModel.level.startPos,
                                isEnd: pos == viewModel.level.endPos,
                                isSolved: viewModel.isSolved,
                                isSnapped: viewModel.isTileSnapped(at: pos),
                                connections: viewModel.connections(for: pos),
                                hasMascot: viewModel.mascotPosition == pos,
                                size: cellSize
                            )
                        }
                    }
                }
            }
            .padding(3)
            .background(Theme.Colors.creamInset)
            .cornerRadius(Theme.CornerRadius.sm)

            // Dynamic Mascot Walking Overlay
            if let mascotPos = viewModel.mascotPosition {
                let x = CGFloat(mascotPos.col) * (cellSize + spacing) + cellSize / 2 + 3
                let y = CGFloat(mascotPos.row) * (cellSize + spacing) + cellSize / 2 + 3

                let mascotAsset: String = {
                    if viewModel.isSolved && viewModel.isCompletedCelebration {
                        return appTheme.assets.mascotCelebrateAssetName
                    } else if viewModel.isRevealing {
                        return appTheme.assets.mascotWalkAssetName
                    } else {
                        return appTheme.assets.mascotIdleAssetName
                    }
                }()

                Image(mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: cellSize * 0.88, height: cellSize * 0.88)
                    .shadow(color: Theme.Colors.woodDark.opacity(0.25), radius: 2, y: 2)
                    .position(x: x, y: y)
                    .animation(.spring(response: 0.28, dampingFraction: 0.65), value: mascotPos)
            }
        }
        .disabled(viewModel.isSolved)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let distance = hypot(value.translation.width, value.translation.height)
                    if distance > 6 {
                        if !isDraggingActive {
                            isDraggingActive = true
                            if let startPos = cellPosition(for: value.startLocation, cellSize: cellSize, spacing: spacing) {
                                viewModel.beginDrag(at: startPos)
                            }
                        }
                        if let currentPos = cellPosition(for: value.location, cellSize: cellSize, spacing: spacing) {
                            viewModel.continueDrag(at: currentPos)
                        }
                    }
                }
                .onEnded { value in
                    if !isDraggingActive {
                        if let tapPos = cellPosition(for: value.location, cellSize: cellSize, spacing: spacing) {
                            viewModel.handleCellTap(at: tapPos)
                        }
                    }
                    viewModel.endDrag()
                    isDraggingActive = false
                }
        )
    }

    // MARK: - Bottom Floating Controls: Restart, Mode Toggle & Hint
    private var bottomControlsView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Restart Level Button (Confirmation alert before resetting)
            Button {
                showingResetConfirmationAlert = true
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .bold))
            }
            .buttonStyle(ChunkyCircleButtonStyle(actionPair: Theme.Colors.secondaryAction, diameter: 40))

            // Mode Toggle Switch (Trilha 🐾 vs Vazio ✕)
            modeToggleSwitch

            // Hint Button (Custom overlay before spending 3 coins)
            Button {
                if progressManager.canAffordHint(cost: 3) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showingHintOverlay = true
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showingInsufficientCoinsOverlay = true
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Dica")
                        .font(Theme.Typography.headline())
                }
            }
            .buttonStyle(
                ChunkyButtonStyle(
                    actionPair: Theme.Colors.rewardAction,
                    lipHeight: Theme.LipHeight.sm,
                    cornerRadius: Theme.CornerRadius.pill,
                    horizontalPadding: Theme.Spacing.md,
                    verticalPadding: Theme.Spacing.xs
                )
            )
            .disabled(viewModel.isSolved)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            Capsule()
                .fill(Theme.Colors.creamSurface)
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.creamOutline, lineWidth: Theme.outlineWidth)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.12), radius: 6, x: 0, y: 3)
        )
    }

    // MARK: - Mode Toggle Switch (Segmented tactile toggle)
    private var modeToggleSwitch: some View {
        HStack(spacing: 0) {
            // Path Segment
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    viewModel.inputMode = .path
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 13))
                    Text("Trilha")
                        .font(Theme.Typography.caption())
                }
                .foregroundColor(viewModel.inputMode == .path ? Theme.Colors.inkInverse : Theme.Colors.inkSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if viewModel.inputMode == .path {
                            Capsule()
                                .fill(activeActionPair.face)
                                .shadow(color: activeActionPair.lip.opacity(0.4), radius: 2, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Empty / Cross Segment
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    viewModel.inputMode = .cross
                }
            } label: {
                HStack(spacing: 4) {
                    Text("✕")
                        .font(.system(size: 13, weight: .heavy))
                    Text("Vazio")
                        .font(Theme.Typography.caption())
                }
                .foregroundColor(viewModel.inputMode == .cross ? Theme.Colors.inkInverse : Theme.Colors.inkSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if viewModel.inputMode == .cross {
                            Capsule()
                                .fill(Theme.Colors.secondaryAction.face)
                                .shadow(color: Theme.Colors.secondaryAction.lip.opacity(0.4), radius: 2, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Theme.Colors.creamInset)
                .overlay(Capsule().stroke(Theme.Colors.creamOutline.opacity(0.8), lineWidth: 1))
        )
    }

    // MARK: - Victory Overlay Modal (Rewarding Coins with celebration)
    private var victoryOverlayView: some View {
        WoodPanel(title: "Fase Concluída!") {
            VStack(spacing: Theme.Spacing.sm) {
                // Mascot Celebration with Target Item
                ZStack(alignment: .bottomTrailing) {
                    Image(appTheme.assets.mascotCelebrateAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 82)
                        .shadow(color: Theme.Colors.woodDark.opacity(0.15), radius: 4, y: 2)

                    Image(appTheme.assets.targetItemAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .offset(x: 8, y: 6)
                        .shadow(color: Theme.Colors.woodDark.opacity(0.15), radius: 3, y: 2)
                }
                .padding(.top, Theme.Spacing.xs)

                // Joyful Coins Badge
                HStack(spacing: 8) {
                    Image("icon_seed_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(animatedCoinsBounced ? -6 : 6))

                    Text("+\(viewModel.lastEarnedCoins) \(viewModel.lastEarnedCoins == 1 ? "Moeda" : "Moedas")")
                        .font(Theme.Typography.title())
                        .foregroundColor(Theme.Colors.rewardAction.lip)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.Colors.creamSurface)
                        .overlay(
                            Capsule().stroke(Theme.Colors.rewardAction.lip.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Theme.Colors.rewardAction.lip.opacity(0.2), radius: 5, y: 2)
                )
                .scaleEffect(animatedCoinsBounced ? 1.05 : 0.95)

                VStack(spacing: Theme.Spacing.xxs) {
                    Text("Caminho Conectado!")
                        .font(Theme.Typography.headline())
                        .foregroundColor(Theme.Colors.inkPrimary)

                    Text("O gatinho encontrou o novelo com sucesso!")
                        .font(Theme.Typography.body())
                        .foregroundColor(Theme.Colors.inkSecondary)
                        .multilineTextAlignment(.center)
                }

                // Current balance pill
                HStack(spacing: 4) {
                    Text("Saldo total:")
                        .font(Theme.Typography.caption())
                        .foregroundColor(Theme.Colors.inkSecondary)
                    Image("icon_seed_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text("\(progressManager.coins)")
                        .font(Theme.Typography.caption())
                        .fontWeight(.heavy)
                        .foregroundColor(Theme.Colors.inkPrimary)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Theme.Colors.woodLight.opacity(0.25))
                        .overlay(Capsule().stroke(Theme.Colors.woodOutline.opacity(0.25), lineWidth: 1))
                )

                // Primary Navigation Buttons
                VStack(spacing: Theme.Spacing.sm) {
                    if let camp = viewModel.campaignLevel {
                        let nextId = camp.id + 1
                        let nextLvl = CampaignLevelGenerator.level(for: nextId)
                        Button {
                            viewModel.loadCampaignLevel(nextLvl)
                        } label: {
                            HStack(spacing: 6) {
                                Text("Próxima Fase")
                                    .font(Theme.Typography.headline())
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.primaryAction))
                    } else {
                        Button {
                            viewModel.nextPuzzle()
                        } label: {
                            Text("Próxima Fase")
                                .font(Theme.Typography.headline())
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.primaryAction))
                    }

                    // Return to Map button
                    Button {
                        onDismiss?()
                        dismiss()
                    } label: {
                        Text("Voltar ao Mapa")
                            .font(Theme.Typography.headline())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.secondaryAction))
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Rewarded Video Modal & Flow (Emergency Coins)
    private func startRewardVideoFlow() {
        rewardProgress = 0.0
        rewardClaimed = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showingRewardModal = true
        }

        withAnimation(.linear(duration: 2.2)) {
            rewardProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            progressManager.addCoins(5)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                rewardClaimed = true
            }
            HapticManager.shared.rewardCollected()
        }
    }

    private var rewardedVideoModalView: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Mascot Celebration / Idle
            Image(rewardClaimed ? appTheme.assets.mascotCelebrateAssetName : appTheme.assets.mascotIdleAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding(.top, Theme.Spacing.xs)

            VStack(spacing: 4) {
                Text(rewardClaimed ? "Recompensa Concedida!" : "Assistindo Vídeo...")
                    .font(Theme.Typography.headline())
                    .foregroundColor(Theme.Colors.inkPrimary)

                Text(rewardClaimed ? "Você ganhou +5 moedas para continuar se divertindo!" : "Aguarde um momento para receber suas moedas de cortesia.")
                    .font(Theme.Typography.caption())
                    .foregroundColor(Theme.Colors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            if !rewardClaimed {
                // Animated cozy progress bar
                GeometryReader { pGeo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.Colors.creamInset)
                        Capsule()
                            .fill(Theme.Colors.rewardAction.face)
                            .frame(width: max(0, pGeo.size.width * rewardProgress))
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, Theme.Spacing.lg)
            } else {
                HStack(spacing: 8) {
                    Image("icon_seed_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                    Text("+5 Moedas!")
                        .font(Theme.Typography.title())
                        .foregroundColor(Theme.Colors.rewardAction.lip)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.Colors.creamSurface)
                        .overlay(Capsule().stroke(Theme.Colors.rewardAction.lip.opacity(0.4), lineWidth: 2))
                )
            }

            if rewardClaimed {
                Button {
                    withAnimation {
                        showingRewardModal = false
                    }
                } label: {
                    Text("Coletar e Continuar")
                        .font(Theme.Typography.headline())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.primaryAction))
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(Theme.Colors.creamSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .stroke(Theme.Colors.creamOutline, lineWidth: 3)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.28), radius: 18, x: 0, y: 8)
        )
        .frame(maxWidth: 320)
    }

    // MARK: - Grid Position Helper
    private func cellPosition(for point: CGPoint, cellSize: CGFloat, spacing: CGFloat) -> GridPosition? {
        let localX = point.x - 3
        let localY = point.y - 3
        guard localX >= 0, localY >= 0 else { return nil }
        let step = cellSize + spacing
        let c = Int(localX / step)
        let r = Int(localY / step)
        guard r >= 0, r < viewModel.level.rows, c >= 0, c < viewModel.level.cols else { return nil }
        return GridPosition(row: r, col: c)
    }

    // MARK: - Hint Confirmation Modal Overlay
    private var hintConfirmationModalView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.rewardAction.face.opacity(0.18))
                    .frame(width: 72, height: 72)
                Image("icon_hint_lamp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
            }
            .padding(.top, Theme.Spacing.xs)

            VStack(spacing: 6) {
                Text("Usar Dica?")
                    .font(Theme.Typography.title())
                    .foregroundColor(Theme.Colors.inkPrimary)

                Text("Revelar o próximo passo do caminho pelo custo de 3 moedas.")
                    .font(Theme.Typography.body())
                    .foregroundColor(Theme.Colors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.sm)
            }

            // Coin cost pill
            HStack(spacing: 6) {
                Image("icon_seed_coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("-3 Moedas")
                    .font(Theme.Typography.headline())
                    .fontWeight(.heavy)
                    .foregroundColor(Theme.Colors.inkPrimary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.Colors.creamInset)
                    .overlay(Capsule().stroke(Theme.Colors.creamOutline, lineWidth: 1.5))
            )

            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingHintOverlay = false
                    }
                    _ = viewModel.usePurchasedHint()
                } label: {
                    Text("Confirmar")
                        .font(Theme.Typography.headline())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.rewardAction))

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingHintOverlay = false
                    }
                } label: {
                    Text("Cancelar")
                        .font(Theme.Typography.headline())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.secondaryAction))
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(Theme.Colors.creamSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .stroke(Theme.Colors.creamOutline, lineWidth: 3)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.28), radius: 18, x: 0, y: 8)
        )
        .frame(maxWidth: 320)
    }

    // MARK: - Insufficient Coins Modal Overlay
    private var insufficientCoinsModalView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.rewardAction.face.opacity(0.18))
                    .frame(width: 68, height: 68)
                Image("icon_seed_coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            .padding(.top, Theme.Spacing.xs)

            VStack(spacing: 6) {
                Text("Moedas Insuficientes")
                    .font(Theme.Typography.title())
                    .foregroundColor(Theme.Colors.inkPrimary)

                Text("Você precisa de 3 moedas para usar uma dica. Assista a um vídeo rápido para ganhar +5 moedas grátis!")
                    .font(Theme.Typography.body())
                    .foregroundColor(Theme.Colors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.sm)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingInsufficientCoinsOverlay = false
                    }
                    startRewardVideoFlow()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                        Text("Assistir Vídeo")
                    }
                    .font(Theme.Typography.headline())
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.rewardAction))

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showingInsufficientCoinsOverlay = false
                    }
                } label: {
                    Text("Agora Não")
                        .font(Theme.Typography.headline())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(actionPair: Theme.Colors.secondaryAction))
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(Theme.Colors.creamSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .stroke(Theme.Colors.creamOutline, lineWidth: 3)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.28), radius: 18, x: 0, y: 8)
        )
        .frame(maxWidth: 320)
    }
}
