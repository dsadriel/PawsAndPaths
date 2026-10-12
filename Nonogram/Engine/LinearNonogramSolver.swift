import Foundation

/// Simulates deterministic human line-by-line deduction to verify that a puzzle
/// can be completely solved without guessing or backtracking.
public struct LinearNonogramSolver {
    public enum DeductionCell: Equatable {
        case unknown
        case path
        case empty
    }

    public enum SolverResult {
        /// Solved completely with deterministic deduction.
        case fullySolved(grid: [[DeductionCell]])
        /// Stalled: requires guessing/branching to progress.
        case requiresGuessing(unknownCount: Int)
        /// Contradiction detected: clues cannot be satisfied.
        case contradictory
    }

    /// Verifies if the given clues yield a unique, deterministic solution.
    public static func solve(
        rows: Int,
        cols: Int,
        rowClues: [[Int]],
        colClues: [[Int]],
        initialKnown: [GridPosition: DeductionCell] = [:]
    ) -> SolverResult {
        var grid = Array(repeating: Array(repeating: DeductionCell.unknown, count: cols), count: rows)
        for (pos, cell) in initialKnown {
            if pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols {
                grid[pos.row][pos.col] = cell
            }
        }

        var changed = true
        var iterationCount = 0
        let maxIterations = rows * cols * 2

        while changed && iterationCount < maxIterations {
            changed = false
            iterationCount += 1

            // 1. Process all rows
            for r in 0..<rows {
                let currentLine = grid[r]
                let clues = rowClues[r]

                guard let deduced = deduceLine(length: cols, clues: clues, current: currentLine) else {
                    return .contradictory
                }

                for c in 0..<cols {
                    if grid[r][c] == .unknown && deduced[c] != .unknown {
                        grid[r][c] = deduced[c]
                        changed = true
                    }
                }
            }

            // 2. Process all columns
            for c in 0..<cols {
                var currentLine: [DeductionCell] = []
                for r in 0..<rows {
                    currentLine.append(grid[r][c])
                }
                let clues = colClues[c]

                guard let deduced = deduceLine(length: rows, clues: clues, current: currentLine) else {
                    return .contradictory
                }

                for r in 0..<rows {
                    if grid[r][c] == .unknown && deduced[r] != .unknown {
                        grid[r][c] = deduced[r]
                        changed = true
                    }
                }
            }
        }

        // Count remaining unknowns
        var unknowns = 0
        for r in 0..<rows {
            for c in 0..<cols {
                if grid[r][c] == .unknown {
                    unknowns += 1
                }
            }
        }

        if unknowns == 0 {
            return .fullySolved(grid: grid)
        } else {
            return .requiresGuessing(unknownCount: unknowns)
        }
    }

    /// Given a line length, clues, and known cells, finds all valid candidate lines.
    /// Returns the intersection: cells that are identical across ALL valid candidates.
    public static func deduceLine(
        length: Int,
        clues: [Int],
        current: [DeductionCell]
    ) -> [DeductionCell]? {
        let cleanClues = clues.filter { $0 > 0 }

        // If clues are empty or [0], the entire line must be empty
        if cleanClues.isEmpty {
            for cell in current where cell == .path {
                return nil // Contradiction
            }
            return Array(repeating: .empty, count: length)
        }

        var candidates: [[DeductionCell]] = []
        var buffer = Array(repeating: DeductionCell.empty, count: length)

        func search(clueIdx: Int, pos: Int) {
            if clueIdx == cleanClues.count {
                // Ensure remaining positions don't violate current known path cells
                for i in pos..<length {
                    if current[i] == .path { return }
                    buffer[i] = .empty
                }
                candidates.append(buffer)
                return
            }

            let blockLen = cleanClues[clueIdx]
            // Calculate minimum space needed for remaining blocks
            let remainingBlocks = cleanClues[(clueIdx + 1)...]
            let remainingSpaceNeeded = remainingBlocks.reduce(0, +) + remainingBlocks.count

            let maxStart = length - remainingSpaceNeeded - blockLen

            for start in pos...maxStart {
                // Can we place empty cells from pos..<start?
                var canPlaceEmpty = true
                for i in pos..<start {
                    if current[i] == .path {
                        canPlaceEmpty = false
                        break
                    }
                    buffer[i] = .empty
                }
                if !canPlaceEmpty {
                    // Cannot skip past a known path cell without covering it
                    break
                }

                // Can we place blockLen path cells from start..<(start + blockLen)?
                var canPlaceBlock = true
                for i in start..<(start + blockLen) {
                    if current[i] == .empty {
                        canPlaceBlock = false
                        break
                    }
                    buffer[i] = .path
                }

                if canPlaceBlock {
                    let nextPos = start + blockLen
                    // If not the last block, there must be at least one empty spacer after it
                    if clueIdx + 1 < cleanClues.count {
                        if nextPos < length && current[nextPos] != .path {
                            buffer[nextPos] = .empty
                            search(clueIdx: clueIdx + 1, pos: nextPos + 1)
                        }
                    } else {
                        search(clueIdx: clueIdx + 1, pos: nextPos)
                    }
                }
            }
        }

        search(clueIdx: 0, pos: 0)

        if candidates.isEmpty {
            return nil // No valid placement matches current constraints
        }

        // Intersection across all valid candidates
        var result = Array(repeating: DeductionCell.unknown, count: length)
        for i in 0..<length {
            let firstState = candidates[0][i]
            var allSame = true
            for cand in candidates {
                if cand[i] != firstState {
                    allSame = false
                    break
                }
            }
            if allSame {
                result[i] = firstState
            }
        }

        return result
    }
}
