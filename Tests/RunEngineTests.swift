import Foundation

@main
struct EngineTestRunner {
    static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if actual != expected {
            print("❌ FAIL [line \(line)]: expected \(expected), got \(actual). \(message)")
            exit(1)
        }
    }

    static func assertTrue(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if !condition {
            print("❌ FAIL [line \(line)]: Condition failed. \(message)")
            exit(1)
        }
    }

    static func main() {
        print("=== Running Nonogram Engine Test Suite ===")

        // 1. Test SplitMix64 deterministic repeatability
        print("Test 1: SplitMix64 Determinism...")
        var prng1 = SplitMix64(seed: 12345)
        var prng2 = SplitMix64(seed: 12345)
        for _ in 0..<100 {
            assertEqual(prng1.next(), prng2.next(), "PRNG must generate identical sequences for identical seeds")
        }
        print("  ✓ SplitMix64 passed")

        // 2. Test Clue Extractor
        print("Test 2: ClueExtractor Run Lengths...")
        let samplePath: Set<GridPosition> = [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 2),
            GridPosition(row: 1, col: 0),
            GridPosition(row: 1, col: 1)
        ]
        let (rowClues, colClues) = ClueExtractor.extractClues(rows: 3, cols: 3, pathPositions: samplePath)
        assertEqual(rowClues, [[1, 1], [2], [0]], "Row clues extraction mismatch")
        assertEqual(colClues, [[2], [1], [1]], "Col clues extraction mismatch")
        print("  ✓ ClueExtractor passed")

        // 3. Test Forward Path Generator Connectivity
        print("Test 3: ForwardPathGenerator Connectivity on arbitrary NxM...")
        let testDimensions = [(5, 5), (6, 8), (10, 10), (4, 7)]
        for (r, c) in testDimensions {
            let gen = ForwardPathGenerator(rows: r, cols: c)
            var rng = SplitMix64(seed: UInt64(r * 100 + c))
            let start = GridPosition(row: 0, col: 0)
            let end = GridPosition(row: r - 1, col: c - 1)
            let (positions, ordered) = gen.generatePath(start: start, end: end, rng: &rng)

            assertTrue(positions.contains(start), "Path must contain start position")
            assertTrue(positions.contains(end), "Path must contain end position")
            assertEqual(ordered.first, start, "Ordered path must start at start")
            assertEqual(ordered.last, end, "Ordered path must end at end")

            // Check step-by-step connectivity
            for i in 0..<(ordered.count - 1) {
                let p1 = ordered[i]
                let p2 = ordered[i + 1]
                assertEqual(p1.manhattanDistance(to: p2), 1, "Path consecutive steps must be adjacent")
            }
        }
        print("  ✓ ForwardPathGenerator passed")

        // 4. Test LinearNonogramSolver
        print("Test 4: LinearNonogramSolver Deduction...")
        let lineDeduction = LinearNonogramSolver.deduceLine(
            length: 5,
            clues: [3],
            current: Array(repeating: .unknown, count: 5)
        )
        assertTrue(lineDeduction != nil, "Deduction must succeed")
        assertEqual(lineDeduction?[2], .path, "Center cell index 2 must be deterministically deduced as .path")

        let solvedResult = LinearNonogramSolver.solve(
            rows: 3,
            cols: 3,
            rowClues: [[1, 1], [2], [0]],
            colClues: [[2], [1], [1]]
        )
        if case .fullySolved(let grid) = solvedResult {
            assertEqual(grid[0][0], .path)
            assertEqual(grid[0][1], .empty)
            assertEqual(grid[0][2], .path)
            assertEqual(grid[1][0], .path)
            assertEqual(grid[1][1], .path)
            assertEqual(grid[1][2], .empty)
            assertEqual(grid[2][0], .empty)
            assertEqual(grid[2][1], .empty)
            assertEqual(grid[2][2], .empty)
        } else {
            print("❌ Expected fullySolved for 3x3 sample")
            exit(1)
        }
        print("  ✓ LinearNonogramSolver passed")

        // 5. Test ProceduralPuzzleGenerator & Edge Endpoints
        print("Test 5: ProceduralPuzzleGenerator & Edge Endpoints...")
        let puzzleGen = ProceduralPuzzleGenerator(rows: 5, cols: 5)
        let level5x5 = puzzleGen.generate(initialSeed: 42)
        assertEqual(level5x5.rows, 5)
        assertEqual(level5x5.cols, 5)
        assertTrue(!level5x5.solutionPath.isEmpty, "Solution path must not be empty")

        // Verify start and end are on edges and distinct
        let isStartOnEdge = level5x5.startPos.row == 0 || level5x5.startPos.row == 4 || level5x5.startPos.col == 0 || level5x5.startPos.col == 4
        let isEndOnEdge = level5x5.endPos.row == 0 || level5x5.endPos.row == 4 || level5x5.endPos.col == 0 || level5x5.endPos.col == 4
        assertTrue(isStartOnEdge, "Start position must be on a perimeter edge")
        assertTrue(isEndOnEdge, "End position must be on a perimeter edge")
        assertTrue(level5x5.startPos != level5x5.endPos, "Start and end must be distinct cells")
        assertTrue(level5x5.solutionPath.contains(level5x5.startPos), "Solution must contain startPos")
        assertTrue(level5x5.solutionPath.contains(level5x5.endPos), "Solution must contain endPos")

        // Verify solver with initialKnown [startPos, endPos]
        let verifySolve = LinearNonogramSolver.solve(
            rows: level5x5.rows,
            cols: level5x5.cols,
            rowClues: level5x5.rowClues,
            colClues: level5x5.colClues,
            initialKnown: [level5x5.startPos: .path, level5x5.endPos: .path]
        )
        if case .fullySolved = verifySolve {
            print("  ✓ Level seed \(level5x5.seed) with edge endpoints (\(level5x5.startPos.row),\(level5x5.startPos.col)) -> (\(level5x5.endPos.row),\(level5x5.endPos.col)) is certified 100% solvable")
        } else {
            print("❌ Level seed \(level5x5.seed) failed zero-guess solver verification")
            exit(1)
        }

        // 6. Test CampaignChapter Level Solvability
        print("Test 6: CampaignChapter Level Generation & Solvability...")
        let sampleLevels = Array(CampaignChapter.chapter1.levels.prefix(3))
        for campLvl in sampleLevels {
            let gen = ProceduralPuzzleGenerator(rows: campLvl.rows, cols: campLvl.cols)
            let lvl = gen.generate(initialSeed: campLvl.seed, title: campLvl.title)
            assertEqual(lvl.rows, campLvl.rows)
            assertEqual(lvl.cols, campLvl.cols)

            let solve = LinearNonogramSolver.solve(
                rows: lvl.rows,
                cols: lvl.cols,
                rowClues: lvl.rowClues,
                colClues: lvl.colClues,
                initialKnown: [lvl.startPos: .path, lvl.endPos: .path]
            )
            if case .fullySolved = solve {
                print("  ✓ Campaign \(campLvl.title) (\(campLvl.rows)x\(campLvl.cols)) seed \(lvl.seed) passed solver")
            } else {
                print("❌ Campaign \(campLvl.title) failed solver")
                exit(1)
            }
        }

        print("=== ALL TESTS PASSED SUCCESSFULLY ===")
    }
}
