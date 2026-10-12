import SwiftUI

public struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var appTheme
    @StateObject private var viewModel: NonogramGameViewModel
    @ObservedObject private var progressManager = CampaignProgressManager.shared

    @State private var animatedCoinsBounced: Bool = false
    @State private var showingHintAlert: Bool = false
    @State private var showingInsufficientCoinsAlert: Bool = false
    private var onDismiss: (() -> Void)?

    public init(campaignLevel: CampaignLevel? = nil, onDismiss: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: NonogramGameViewModel(campaignLevel: campaignLevel))
        self.onDismiss = onDismiss
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
                            .clipped()
                            .overlay(Color.black.opacity(0.04))
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
                        .padding(.top, Theme.Spacing.sm)

                    Spacer(minLength: Theme.Spacing.xs)

                    // Grid expands horizontally with clear card separation
                    boardContainerView
                        .padding(.horizontal, Theme.Spacing.md)

                    Spacer(minLength: Theme.Spacing.xs)

                    // Bottom controls: Hidden smoothly when puzzle is solved / during celebration
                    if !viewModel.isSolved {
                        bottomControlsView
                            .padding(.bottom, Theme.Spacing.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(width: screenGeo.size.width, height: screenGeo.size.height)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.isSolved)

                // Victory Modal Overlay
                if viewModel.isCompletedCelebration {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    victoryOverlayView
                        .padding(.horizontal, Theme.Spacing.xl)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .frame(width: screenGeo.size.width, height: screenGeo.size.height)
        }
        .navigationBarHidden(true)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if viewModel.isSolved && !viewModel.isCompletedCelebration {
                        viewModel.isHoldingScreen = true
                    }
                }
                .onEnded { _ in
                    viewModel.isHoldingScreen = false
                }
        )
        .alert("Usar Dica", isPresented: $showingHintAlert) {
            Button("Confirmar (3 🪙)") {
                _ = viewModel.usePurchasedHint()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Deseja gastar 3 moedas para revelar o próximo passo do caminho?")
        }
        .alert("Moedas Insuficientes", isPresented: $showingInsufficientCoinsAlert) {
            Button("Entendi", role: .cancel) {}
        } message: {
            Text("Você precisa de 3 moedas para usar uma dica. Conclua fases para ganhar mais moedas!")
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
                .buttonStyle(ChunkyCircleButtonStyle(actionPair: Theme.Colors.secondaryAction, diameter: 42))
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(width: 42)
            }

            Spacer()

            // Header Title: "Fase X" (bold), subtitle below
            VStack(spacing: 2) {
                Text("Fase \(viewModel.campaignLevel?.id ?? 1)")
                    .font(Theme.Typography.headline())
                    .fontWeight(.heavy)
                    .foregroundColor(Theme.Colors.inkPrimary)

                Text(viewModel.campaignLevel?.subtitle ?? "O Gatinho e o Novelo")
                    .font(Theme.Typography.caption())
                    .foregroundColor(Theme.Colors.inkSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Theme.Colors.creamSurface.opacity(0.94))
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.creamOutline.opacity(0.85), lineWidth: 1.5)
                    )
                    .shadow(color: Theme.Colors.woodDark.opacity(0.08), radius: 4, y: 2)
            )

            Spacer()

            if !viewModel.isSolved {
                Button {
                    viewModel.resetCurrentLevel()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .bold))
                }
                .buttonStyle(ChunkyCircleButtonStyle(actionPair: Theme.Colors.disabledAction, diameter: 42))
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(width: 42)
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
                        let step = cellSize + spacing
                        let c = Int((value.location.x - 3) / step)
                        let r = Int((value.location.y - 3) / step)
                        let pos = GridPosition(row: r, col: c)
                        viewModel.continueDrag(at: pos)
                    }
                }
                .onEnded { value in
                    let distance = hypot(value.translation.width, value.translation.height)
                    if distance <= 6 {
                        let step = cellSize + spacing
                        let c = Int((value.location.x - 3) / step)
                        let r = Int((value.location.y - 3) / step)
                        let pos = GridPosition(row: r, col: c)
                        viewModel.handleCellTap(at: pos)
                    }
                    viewModel.endDrag()
                }
        )
    }

    // MARK: - Bottom Floating Controls: Mode Toggle & Hint
    private var bottomControlsView: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Mode Toggle Switch (Trilha 🐾 vs Vazio ✕)
            modeToggleSwitch

            // Hint Button (Confirmation alert before spending 3 coins)
            Button {
                if progressManager.canAffordHint(cost: 3) {
                    showingHintAlert = true
                } else {
                    showingInsufficientCoinsAlert = true
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
        .padding(.horizontal, Theme.Spacing.md)
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
                                .fill(Theme.Colors.primaryAction.face)
                                .shadow(color: Theme.Colors.primaryAction.lip.opacity(0.4), radius: 2, y: 1)
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

    // MARK: - Victory Overlay Modal (Rewarding +5 Coins with celebration)
    private var victoryOverlayView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(Theme.Colors.creamSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .stroke(Theme.Colors.creamOutline, lineWidth: 3)
                )
                .shadow(color: Theme.Colors.woodDark.opacity(0.22), radius: 16, x: 0, y: 8)

            VStack(spacing: Theme.Spacing.md) {
                // Mascot Celebration with Target Item
                ZStack(alignment: .bottomTrailing) {
                    Image(appTheme.assets.mascotCelebrateAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 86, height: 86)
                        .shadow(color: Theme.Colors.woodDark.opacity(0.15), radius: 4, y: 2)

                    Image(appTheme.assets.targetItemAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .offset(x: 8, y: 6)
                        .shadow(color: Theme.Colors.woodDark.opacity(0.15), radius: 3, y: 2)
                }
                .padding(.top, Theme.Spacing.xs)

                // Joyful +5 Coins Badge
                HStack(spacing: 8) {
                    Image("icon_seed_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(animatedCoinsBounced ? -6 : 6))

                    Text("+5 Moedas")
                        .font(Theme.Typography.title())
                        .foregroundColor(Theme.Colors.rewardAction.lip)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Theme.Colors.creamSurface)
                        .overlay(
                            Capsule().stroke(Theme.Colors.rewardAction.lip.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Theme.Colors.rewardAction.lip.opacity(0.2), radius: 6, y: 3)
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

                if let camp = viewModel.campaignLevel {
                    let nextId = camp.id + 1
                    let nextLvl = CampaignLevelGenerator.level(for: nextId)
                    Button {
                        viewModel.loadCampaignLevel(nextLvl)
                    } label: {
                        HStack(spacing: 6) {
                            Text("Próxima Fase (\(nextId))")
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
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .frame(maxWidth: 340)
    }
}
