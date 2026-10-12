import Foundation

/// A complete Nonogram puzzle definition.
public struct PuzzleLevel: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let seed: UInt64
    public let rows: Int
    public let cols: Int
    public let startPos: GridPosition
    public let endPos: GridPosition
    public let solutionPath: Set<GridPosition>
    public let orderedPath: [GridPosition]
    public let rowClues: [[Int]]
    public let colClues: [[Int]]

    public init(
        id: UUID = UUID(),
        title: String = "O Gatinho e o Novelo",
        seed: UInt64,
        rows: Int,
        cols: Int,
        startPos: GridPosition,
        endPos: GridPosition,
        solutionPath: Set<GridPosition>,
        orderedPath: [GridPosition] = [],
        rowClues: [[Int]],
        colClues: [[Int]]
    ) {
        self.id = id
        self.title = title
        self.seed = seed
        self.rows = rows
        self.cols = cols
        self.startPos = startPos
        self.endPos = endPos
        self.solutionPath = solutionPath
        self.orderedPath = orderedPath.isEmpty ? Array(solutionPath) : orderedPath
        self.rowClues = rowClues
        self.colClues = colClues
    }

    /// Checks if a given row in player's grid matches the target row clue.
    public func isRowClueSatisfied(_ playerRow: [CellState], rowIndex: Int) -> Bool {
        let currentRuns = Self.runs(in: playerRow)
        return currentRuns == rowClues[rowIndex]
    }

    /// Checks if a given col in player's grid matches the target col clue.
    public func isColClueSatisfied(_ playerCol: [CellState], colIndex: Int) -> Bool {
        let currentRuns = Self.runs(in: playerCol)
        return currentRuns == colClues[colIndex]
    }

    /// Computes run-length clues for a line of cell states.
    public static func runs(in line: [CellState]) -> [Int] {
        var runs: [Int] = []
        var currentCount = 0
        for cell in line {
            if cell.isPath {
                currentCount += 1
            } else if currentCount > 0 {
                runs.append(currentCount)
                currentCount = 0
            }
        }
        if currentCount > 0 {
            runs.append(currentCount)
        }
        return runs.isEmpty ? [0] : runs
    }
}
