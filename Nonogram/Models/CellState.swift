import Foundation

/// State of a single grid cell on the player's board.
public enum CellState: Int, Codable, Equatable, Sendable {
    case empty = 0
    case path = 1
    case crossed = 2

    public var isPath: Bool {
        self == .path
    }

    public var isCrossed: Bool {
        self == .crossed
    }
}

/// The player's active painting mode.
public enum InputMode: String, CaseIterable, Identifiable, Sendable {
    case path = "Trilha"
    case cross = "Vazio"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .path: return "🐾"
        case .cross: return "✕"
        }
    }
}

/// Dynamic connection flags indicating adjacent path neighbors (for track autotiling).
public struct TileConnection: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let north = TileConnection(rawValue: 1 << 0)
    public static let south = TileConnection(rawValue: 1 << 1)
    public static let east  = TileConnection(rawValue: 1 << 2)
    public static let west  = TileConnection(rawValue: 1 << 3)

    public static func connections(for pos: GridPosition, in pathPositions: Set<GridPosition>) -> TileConnection {
        var flags: TileConnection = []
        if pathPositions.contains(GridPosition(row: pos.row - 1, col: pos.col)) { flags.insert(.north) }
        if pathPositions.contains(GridPosition(row: pos.row + 1, col: pos.col)) { flags.insert(.south) }
        if pathPositions.contains(GridPosition(row: pos.row, col: pos.col + 1)) { flags.insert(.east) }
        if pathPositions.contains(GridPosition(row: pos.row, col: pos.col - 1)) { flags.insert(.west) }
        return flags
    }

    /// Calculates connections strictly between the preceding and succeeding steps along the sequential journey.
    public static func connections(for pos: GridPosition, in orderedPath: [GridPosition]) -> TileConnection {
        guard let idx = orderedPath.firstIndex(of: pos) else { return [] }
        var neighbors: [GridPosition] = []
        if idx > 0 {
            neighbors.append(orderedPath[idx - 1])
        }
        if idx + 1 < orderedPath.count {
            neighbors.append(orderedPath[idx + 1])
        }

        var flags: TileConnection = []
        for n in neighbors {
            if n == GridPosition(row: pos.row - 1, col: pos.col) { flags.insert(.north) }
            if n == GridPosition(row: pos.row + 1, col: pos.col) { flags.insert(.south) }
            if n == GridPosition(row: pos.row, col: pos.col + 1) { flags.insert(.east) }
            if n == GridPosition(row: pos.row, col: pos.col - 1) { flags.insert(.west) }
        }
        return flags
    }
}
