import Foundation

/// Generates a valid connected path on an N x M grid connecting startPos to endPos.
public struct ForwardPathGenerator {
    public let rows: Int
    public let cols: Int

    public init(rows: Int, cols: Int) {
        self.rows = max(3, rows)
        self.cols = max(3, cols)
    }

    /// Generates a connected path between startPos and endPos using deterministic PRNG.
    /// Returns the set of path positions and the ordered sequence from start to end.
    public func generatePath(
        start: GridPosition? = nil,
        end: GridPosition? = nil,
        rng: inout SplitMix64
    ) -> (positions: Set<GridPosition>, orderedPath: [GridPosition]) {
        let startPos = start ?? GridPosition(row: 0, col: 0)
        let endPos = end ?? GridPosition(row: rows - 1, col: cols - 1)

        // Target path length: roughly 35% - 55% of total grid cells to ensure interesting clues.
        let minLength = max(rows + cols - 1, Int(Double(rows * cols) * 0.35))
        let maxLength = max(minLength, Int(Double(rows * cols) * 0.60))

        // Attempt generating a meandering self-avoiding walk
        for _ in 0..<100 {
            if let path = tryGenerateWalk(from: startPos, to: endPos, minLength: minLength, maxLength: maxLength, rng: &rng) {
                return (Set(path), path)
            }
        }

        // Fallback: guaranteed simple Manhattan walk with jitter
        let fallback = fallbackWalk(from: startPos, to: endPos, rng: &rng)
        return (Set(fallback), fallback)
    }

    private func tryGenerateWalk(
        from start: GridPosition,
        to end: GridPosition,
        minLength: Int,
        maxLength: Int,
        rng: inout SplitMix64
    ) -> [GridPosition]? {
        var current = start
        var visited = Set<GridPosition>([start])
        var path = [start]

        while current != end && path.count < maxLength {
            let neighbors = current.orthogonalNeighbors(rows: rows, cols: cols)
                .filter { !visited.contains($0) }

            if neighbors.isEmpty {
                return nil // Dead end
            }

            // Bias choices: If path is still short, prefer moves that don't immediately approach the end.
            // If path length is adequate, bias towards the end.
            let sortedNeighbors: [GridPosition]
            if path.count < minLength {
                // Shuffle to encourage meandering
                sortedNeighbors = neighbors.shuffled(using: &rng)
            } else {
                // Bias towards target
                sortedNeighbors = neighbors.sorted {
                    let d1 = $0.manhattanDistance(to: end)
                    let d2 = $1.manhattanDistance(to: end)
                    if d1 == d2 {
                        return rng.nextDouble() > 0.5
                    }
                    return d1 < d2
                }
            }

            guard let next = sortedNeighbors.first else { return nil }
            visited.insert(next)
            path.append(next)
            current = next
        }

        if current == end && path.count >= minLength {
            return path
        }
        return nil
    }

    private func fallbackWalk(
        from start: GridPosition,
        to end: GridPosition,
        rng: inout SplitMix64
    ) -> [GridPosition] {
        var path = [start]
        var curr = start
        while curr != end {
            var candidates: [GridPosition] = []
            if curr.row < end.row { candidates.append(GridPosition(row: curr.row + 1, col: curr.col)) }
            if curr.row > end.row { candidates.append(GridPosition(row: curr.row - 1, col: curr.col)) }
            if curr.col < end.col { candidates.append(GridPosition(row: curr.row, col: curr.col + 1)) }
            if curr.col > end.col { candidates.append(GridPosition(row: curr.row, col: curr.col - 1)) }

            let next = candidates[rng.nextInt(upperBound: candidates.count)]
            path.append(next)
            curr = next
        }
        return path
    }
}
