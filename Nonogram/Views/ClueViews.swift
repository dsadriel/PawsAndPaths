import SwiftUI

/// Column clues displayed above the grid.
public struct ColumnClueView: View {
    public let clues: [Int]
    public let isSatisfied: Bool
    public let cellSize: CGFloat

    public var body: some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)
            ForEach(Array(clues.enumerated()), id: \.offset) { _, clue in
                Text("\(clue)")
                    .font(Theme.Typography.clue(size: min(22, max(13, cellSize * 0.28))))
                    .foregroundColor(isSatisfied ? Theme.Colors.inkSecondary.opacity(0.35) : Theme.Colors.inkPrimary)
                    .scaleEffect(isSatisfied ? 0.92 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSatisfied)
            }
        }
        .frame(width: cellSize)
        .padding(.bottom, 6)
    }
}

/// Row clues displayed to the left of the grid.
public struct RowClueView: View {
    public let clues: [Int]
    public let isSatisfied: Bool
    public let cellSize: CGFloat

    public var body: some View {
        HStack(spacing: 4) {
            Spacer(minLength: 0)
            ForEach(Array(clues.enumerated()), id: \.offset) { _, clue in
                Text("\(clue)")
                    .font(Theme.Typography.clue(size: min(22, max(13, cellSize * 0.28))))
                    .foregroundColor(isSatisfied ? Theme.Colors.inkSecondary.opacity(0.35) : Theme.Colors.inkPrimary)
                    .scaleEffect(isSatisfied ? 0.92 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSatisfied)
            }
        }
        .frame(height: cellSize)
        .padding(.trailing, 6)
        .padding(.leading, 6)
    }
}
