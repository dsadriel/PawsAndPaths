import Foundation

/// Represents a 0-indexed coordinate in an N x M grid.
public struct GridPosition: Hashable, Codable, Comparable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    public static func < (lhs: GridPosition, rhs: GridPosition) -> Bool {
        if lhs.row == rhs.row {
            return lhs.col < rhs.col
        }
        return lhs.row < rhs.row
    }

    /// Manhattan distance between two positions.
    public func manhattanDistance(to other: GridPosition) -> Int {
        abs(row - other.row) + abs(col - other.col)
    }

    /// The 4-orthogonal neighbors within [0..<rows, 0..<cols].
    public func orthogonalNeighbors(rows: Int, cols: Int) -> [GridPosition] {
        var neighbors: [GridPosition] = []
        if row > 0 { neighbors.append(GridPosition(row: row - 1, col: col)) }
        if row + 1 < rows { neighbors.append(GridPosition(row: row + 1, col: col)) }
        if col > 0 { neighbors.append(GridPosition(row: row, col: col - 1)) }
        if col + 1 < cols { neighbors.append(GridPosition(row: row, col: col + 1)) }
        return neighbors
    }
}
