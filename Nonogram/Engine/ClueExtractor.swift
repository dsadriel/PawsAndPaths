import Foundation

/// Extracts Nonogram numerical constraints (row and column run-lengths) from a path grid.
public struct ClueExtractor {
    /// Extracts both row and column clues for an N x M grid.
    public static func extractClues(
        rows: Int,
        cols: Int,
        pathPositions: Set<GridPosition>
    ) -> (rowClues: [[Int]], colClues: [[Int]]) {
        var rowClues: [[Int]] = []
        var colClues: [[Int]] = []

        // Row clues
        for r in 0..<rows {
            var runs: [Int] = []
            var count = 0
            for c in 0..<cols {
                if pathPositions.contains(GridPosition(row: r, col: c)) {
                    count += 1
                } else if count > 0 {
                    runs.append(count)
                    count = 0
                }
            }
            if count > 0 { runs.append(count) }
            rowClues.append(runs.isEmpty ? [0] : runs)
        }

        // Column clues
        for c in 0..<cols {
            var runs: [Int] = []
            var count = 0
            for r in 0..<rows {
                if pathPositions.contains(GridPosition(row: r, col: c)) {
                    count += 1
                } else if count > 0 {
                    runs.append(count)
                    count = 0
                }
            }
            if count > 0 { runs.append(count) }
            colClues.append(runs.isEmpty ? [0] : runs)
        }

        return (rowClues, colClues)
    }
}
