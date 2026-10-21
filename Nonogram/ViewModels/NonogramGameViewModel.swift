import SwiftUI
import Combine

@MainActor
public final class NonogramGameViewModel: ObservableObject {
    // MARK: - Published State
    @Published public private(set) var level: PuzzleLevel
    @Published public private(set) var grid: [[CellState]]
    @Published public var inputMode: InputMode = .path
    @Published public private(set) var isSolved: Bool = false
    @Published public private(set) var rowSatisfaction: [Bool] = []
    @Published public private(set) var colSatisfaction: [Bool] = []
    @Published public private(set) var elapsedSeconds: Int = 0

    // Campaign Level Association
    @Published public private(set) var campaignLevel: CampaignLevel? = nil

    // Revelation & Mascot Journey State
    @Published public private(set) var revealedTileCount: Int = 0
    @Published public private(set) var mascotPosition: GridPosition? = nil
    @Published public private(set) var isRevealing: Bool = false
    @Published public private(set) var isCompletedCelebration: Bool = false
    @Published public var isHoldingScreen: Bool = false
    @Published public private(set) var lastEarnedCoins: Int = 5
    @Published public private(set) var revealedHintPositions: Set<GridPosition> = []
    private var revelationTask: Task<Void, Never>? = nil

    // Configuration
    @Published public var selectedRows: Int = 5
    @Published public var selectedCols: Int = 5
    @Published public var currentSeedText: String = "1042"

    // MARK: - Internal State
    private var dragTargetState: CellState? = nil
    private var visitedDuringDrag: Set<GridPosition> = []
    private var timerCancellable: AnyCancellable?

    public init(
        campaignLevel: CampaignLevel? = nil,
        rows: Int? = nil,
        cols: Int? = nil,
        seed: UInt64? = nil
    ) {
        self.campaignLevel = campaignLevel
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let defaultRows = isPad ? 5 : 6
        let defaultCols = isPad ? 5 : 4
        let r = campaignLevel?.rows ?? rows ?? defaultRows
        let c = campaignLevel?.cols ?? cols ?? defaultCols
        let s = campaignLevel?.seed ?? seed ?? 1042
        let title = campaignLevel != nil ? "\(campaignLevel!.title): \(campaignLevel!.subtitle)" : "O Gatinho e o Novelo"

        self.selectedRows = r
        self.selectedCols = c
        self.currentSeedText = "\(s)"

        let generator = ProceduralPuzzleGenerator(rows: r, cols: c)
        let generatedLevel = generator.generate(initialSeed: s, title: title)
        self.level = generatedLevel

        if let camp = campaignLevel,
           let saved = CampaignProgressManager.shared.loadLevelProgress(id: camp.id),
           saved.grid.count == r && saved.grid.first?.count == c {
            self.grid = saved.grid
            self.elapsedSeconds = saved.elapsedSeconds
            self.revealedHintPositions = Set(saved.hints)
        } else {
            self.grid = Self.makeInitialGrid(for: generatedLevel)
            self.elapsedSeconds = 0
            self.revealedHintPositions = []
        }
        self.mascotPosition = generatedLevel.startPos

        startTimer()
        updateSatisfaction()
    }

    // MARK: - Level Generation & Reset
    public func loadLevel(rows: Int? = nil, cols: Int? = nil, seed: UInt64? = nil, title: String? = nil) {
        revelationTask?.cancel()
        revelationTask = nil
        revealedTileCount = 0
        isRevealing = false
        isCompletedCelebration = false

        let r = rows ?? selectedRows
        let c = cols ?? selectedCols
        let s = seed ?? (UInt64(currentSeedText) ?? UInt64.random(in: 1..<100000))
        let levelTitle = title ?? (campaignLevel != nil ? "\(campaignLevel!.title): \(campaignLevel!.subtitle)" : "O Gatinho e o Novelo")

        self.selectedRows = r
        self.selectedCols = c
        self.currentSeedText = "\(s)"

        let generator = ProceduralPuzzleGenerator(rows: r, cols: c)
        self.level = generator.generate(initialSeed: s, title: levelTitle)
        self.grid = Self.makeInitialGrid(for: self.level)
        self.mascotPosition = self.level.startPos
        self.isSolved = false
        self.elapsedSeconds = 0
        self.revealedHintPositions.removeAll()

        updateSatisfaction()
        startTimer()
    }

    public func loadCampaignLevel(_ campaign: CampaignLevel) {
        self.campaignLevel = campaign
        loadLevel(
            rows: campaign.rows,
            cols: campaign.cols,
            seed: campaign.seed,
            title: "\(campaign.title): \(campaign.subtitle)"
        )
        // Restore saved in-progress state if player was previously playing this level
        if let saved = CampaignProgressManager.shared.loadLevelProgress(id: campaign.id),
           saved.grid.count == campaign.rows && saved.grid.first?.count == campaign.cols {
            self.grid = saved.grid
            self.elapsedSeconds = saved.elapsedSeconds
            self.revealedHintPositions = Set(saved.hints)
            updateSatisfaction()
        }
    }

    public func resetCurrentLevel() {
        revelationTask?.cancel()
        revelationTask = nil
        revealedTileCount = 0
        self.mascotPosition = level.startPos
        isRevealing = false
        isCompletedCelebration = false

        // Preserve all bought hints/clues on reset!
        var newGrid = Self.makeInitialGrid(for: level)
        for pos in revealedHintPositions {
            if level.solutionPath.contains(pos) {
                newGrid[pos.row][pos.col] = .path
            } else {
                newGrid[pos.row][pos.col] = .crossed
            }
        }

        self.grid = newGrid
        self.isSolved = false
        self.elapsedSeconds = 0
        updateSatisfaction()
        persistCurrentProgressIfNeeded()
        startTimer()
    }

    public func nextPuzzle() {
        let nextSeed = level.seed &+ 1
        loadLevel(rows: selectedRows, cols: selectedCols, seed: nextSeed)
    }

    /// Whether a position is a fixed anchor (start or end) that cannot be modified by the player.
    public func isFixed(_ pos: GridPosition) -> Bool {
        pos == level.startPos || pos == level.endPos
    }

    private static func makeInitialGrid(for lvl: PuzzleLevel) -> [[CellState]] {
        var g = Array(repeating: Array(repeating: CellState.empty, count: lvl.cols), count: lvl.rows)
        if lvl.startPos.row >= 0 && lvl.startPos.row < lvl.rows && lvl.startPos.col >= 0 && lvl.startPos.col < lvl.cols {
            g[lvl.startPos.row][lvl.startPos.col] = .path
        }
        if lvl.endPos.row >= 0 && lvl.endPos.row < lvl.rows && lvl.endPos.col >= 0 && lvl.endPos.col < lvl.cols {
            g[lvl.endPos.row][lvl.endPos.col] = .path
        }
        return g
    }

    // MARK: - Interaction & Tap Handling (Guided by inputMode: Trilha vs Vazio)
    public func handleCellTap(at pos: GridPosition) {
        guard !isSolved, isValid(pos), !isFixed(pos) else { return }

        let current = grid[pos.row][pos.col]
        let newState: CellState

        switch inputMode {
        case .path:
            newState = (current == .path) ? .empty : .path
        case .cross:
            newState = (current == .crossed) ? .empty : .crossed
        }

        applyCellState(newState, at: pos)
        triggerHaptic(for: newState)
        checkVictory()
    }

    public func beginDrag(at pos: GridPosition) {
        guard !isSolved, isValid(pos), !isFixed(pos) else { return }
        visitedDuringDrag.removeAll()

        let current = grid[pos.row][pos.col]
        let target: CellState
        switch inputMode {
        case .path:
            target = (current == .path) ? .empty : .path
        case .cross:
            target = (current == .crossed) ? .empty : .crossed
        }

        dragTargetState = target
        continueDrag(at: pos)
    }

    public func continueDrag(at pos: GridPosition) {
        guard !isSolved, isValid(pos), !isFixed(pos), let target = dragTargetState else { return }
        guard !visitedDuringDrag.contains(pos) else { return }

        visitedDuringDrag.insert(pos)
        if grid[pos.row][pos.col] != target {
            applyCellState(target, at: pos)
            triggerHaptic(for: target)
            checkVictory()
        }
    }

    public func endDrag() {
        dragTargetState = nil
        visitedDuringDrag.removeAll()
    }

    // MARK: - Gentle Hint (Reveals next undiscovered step along ordered journey)
    public func provideHint() {
        guard !isSolved else { return }

        // 1. Reveal the first undiscovered path tile along the sequential journey
        for pos in level.orderedPath {
            if isFixed(pos) { continue }
            if grid[pos.row][pos.col] != .path {
                revealedHintPositions.insert(pos)
                applyCellState(.path, at: pos)
                triggerHaptic(for: .path)
                checkVictory()
                return
            }
        }

        // 2. If all solution tiles are marked, gently clear any mistakenly marked non-path tile
        for r in 0..<level.rows {
            for c in 0..<level.cols {
                let pos = GridPosition(row: r, col: c)
                if !level.solutionPath.contains(pos) && grid[r][c] == .path {
                    revealedHintPositions.insert(pos)
                    applyCellState(.crossed, at: pos)
                    triggerHaptic(for: .crossed)
                    checkVictory()
                    return
                }
            }
        }
    }

    // MARK: - Helpers
    private func isValid(_ pos: GridPosition) -> Bool {
        pos.row >= 0 && pos.row < level.rows && pos.col >= 0 && pos.col < level.cols
    }

    private func applyCellState(_ state: CellState, at pos: GridPosition) {
        grid[pos.row][pos.col] = state
        updateSatisfaction()
        persistCurrentProgressIfNeeded()
    }

    public func persistCurrentProgressIfNeeded() {
        guard let camp = campaignLevel, !isSolved else { return }
        CampaignProgressManager.shared.saveLevelProgress(
            id: camp.id,
            grid: grid,
            elapsedSeconds: elapsedSeconds,
            hints: Array(revealedHintPositions)
        )
    }

    private func triggerHaptic(for state: CellState) {
        switch state {
        case .path:
            HapticManager.shared.pathPlaced()
        case .crossed:
            HapticManager.shared.crossPlaced()
        case .empty:
            HapticManager.shared.cellCleared()
        }
    }

    private func updateSatisfaction() {
        var newRowSat: [Bool] = []
        for r in 0..<level.rows {
            newRowSat.append(level.isRowClueSatisfied(grid[r], rowIndex: r))
        }

        var newColSat: [Bool] = []
        for c in 0..<level.cols {
            var colSlice: [CellState] = []
            for r in 0..<level.rows {
                colSlice.append(grid[r][c])
            }
            newColSat.append(level.isColClueSatisfied(colSlice, colIndex: c))
        }

        self.rowSatisfaction = newRowSat
        self.colSatisfaction = newColSat
    }

    public func isTileSnapped(at pos: GridPosition) -> Bool {
        guard isSolved else { return false }
        if let idx = level.orderedPath.firstIndex(of: pos) {
            return idx < revealedTileCount
        }
        return false
    }

    public func connections(for pos: GridPosition) -> TileConnection {
        TileConnection.connections(for: pos, in: level.orderedPath)
    }

    /// Purchases and applies a hint for 3 coins. Returns true if successful.
    public func usePurchasedHint() -> Bool {
        guard !isSolved else { return false }
        if CampaignProgressManager.shared.purchaseHint(cost: 3) {
            provideHint()
            return true
        }
        return false
    }

    private func checkVictory() {
        guard !isSolved else { return }
        var currentPaths = Set<GridPosition>()
        for r in 0..<level.rows {
            for c in 0..<level.cols {
                if grid[r][c] == .path {
                    currentPaths.insert(GridPosition(row: r, col: c))
                }
            }
        }

        if currentPaths == level.solutionPath {
            isSolved = true
            timerCancellable?.cancel()
            startSnapAndPopSequence()
        }
    }

    private func startSnapAndPopSequence() {
        revelationTask?.cancel()
        revelationTask = Task { @MainActor in
            isRevealing = true
            revealedTileCount = 0
            mascotPosition = level.startPos

            let baseDelayNs: UInt64 = 70_000_000

            // Phase 1: Rapid Snap & Pop sequence along the ordered path
            for (idx, _) in level.orderedPath.enumerated() {
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                    revealedTileCount = idx + 1
                }
                HapticManager.shared.pathPlaced()
                let delay = isHoldingScreen ? 20_000_000 : baseDelayNs
                try? await Task.sleep(nanoseconds: delay)
            }

            try? await Task.sleep(nanoseconds: isHoldingScreen ? 40_000_000 : 120_000_000)

            // Phase 2: Mascot hops along the completed path to the yarn ball
            // Same duration as reveal animation (70ms per step), faster if screen held (20ms)
            for pos in level.orderedPath {
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                    mascotPosition = pos
                }
                HapticManager.shared.cellCleared()
                let delay = isHoldingScreen ? 20_000_000 : baseDelayNs
                try? await Task.sleep(nanoseconds: delay)
            }

            // Brief pause at yarn ball destination so player enjoys arrival
            try? await Task.sleep(nanoseconds: isHoldingScreen ? 180_000_000 : 550_000_000)

            // Phase 3: Final celebration modal
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isCompletedCelebration = true
            }
            HapticManager.shared.victory()

            // Notify campaign progress: awards coins (5 for first completion, 1 for replay)
            if let camp = campaignLevel {
                lastEarnedCoins = CampaignProgressManager.shared.completeLevel(id: camp.id, elapsedSeconds: elapsedSeconds)
            } else {
                lastEarnedCoins = 5
            }
        }
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, !self.isSolved else { return }
                self.elapsedSeconds += 1
            }
    }

    public func setSimulatedVictoryState() {
        self.isSolved = true
        self.isCompletedCelebration = true
    }
}
