import SwiftUI

public struct CellView: View {
    @Environment(\.appTheme) private var appTheme

    public let state: CellState
    public let pos: GridPosition
    public let isStart: Bool
    public let isEnd: Bool
    public let isSolved: Bool
    public let isSnapped: Bool
    public let connections: TileConnection
    public let hasMascot: Bool
    public let size: CGFloat

    public var body: some View {
        Group {
            if isSolved && state.isPath && isSnapped {
                // Revealed Paved Trail Segment
                PavedTrackView(
                    connections: connections,
                    isStart: isStart,
                    isEnd: isEnd,
                    hasMascot: hasMascot,
                    size: size
                )
                .scaleEffect(isSnapped ? 1.0 : 0.82)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSnapped)
            } else if isSolved && !state.isPath {
                // Peaceful meadow tile outside the path
                RoundedRectangle(cornerRadius: max(3, size * appTheme.board.cellCornerRadiusRatio))
                    .fill(appTheme.colors.boardCell)
                    .overlay(
                        RoundedRectangle(cornerRadius: max(3, size * appTheme.board.cellCornerRadiusRatio))
                            .stroke(appTheme.colors.board.opacity(0.35), lineWidth: 1)
                    )
                    .frame(width: size, height: size)
            } else {
                // Field Journal / Solving Phase
                sketchCellView
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Sketch / Diary Mode
    private var sketchCellView: some View {
        ZStack {
            // Diary Paper Tile
            RoundedRectangle(cornerRadius: max(3, size * appTheme.board.cellCornerRadiusRatio))
                .fill(sketchBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: max(3, size * appTheme.board.cellCornerRadiusRatio))
                        .stroke(Theme.Colors.creamOutline.opacity(0.85), lineWidth: 1)
                )

            // Content inside sketch cell
            if isStart {
                pathBlockView
                // Start tile base marker / mat
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: size * 0.52, height: size * 0.52)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: size * 0.28))
                        .foregroundColor(Color.white.opacity(0.70))
                }
            } else if isEnd {
                pathBlockView
                // Target item
                Image(appTheme.assets.targetItemAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.72, height: size * 0.72)
                    .shadow(color: Theme.Colors.woodDark.opacity(0.35), radius: 2, y: 1)
            } else {
                switch state {
                case .path:
                    pathBlockView
                        .transition(.scale(scale: 0.82).combined(with: .opacity))

                case .crossed:
                    // Delicate cozy pencil 'X'
                    Text("✕")
                        .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.inkSecondary.opacity(0.55))
                        .transition(.opacity)

                case .empty:
                    EmptyView()
                }
            }
        }
    }

    private var pathBlockView: some View {
        ZStack(alignment: .bottom) {
            // Lip shadow
            RoundedRectangle(cornerRadius: max(2, size * 0.14))
                .fill(Theme.Colors.woodDark)
                .frame(width: size * 0.82, height: size * 0.82)
                .offset(y: 1.5)

            // Block face
            RoundedRectangle(cornerRadius: max(2, size * 0.14))
                .fill(appTheme.colors.track)
                .frame(width: size * 0.82, height: size * 0.82)
                .overlay(
                    // Subtle top highlight
                    RoundedRectangle(cornerRadius: max(2, size * 0.14))
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }

    private var sketchBackground: Color {
        if isStart || isEnd {
            return Theme.Colors.creamInset
        }
        switch state {
        case .path:
            return Theme.Colors.creamInset
        case .crossed:
            return Theme.Colors.creamSurface.opacity(0.85)
        case .empty:
            return Theme.Colors.creamSurface
        }
    }
}
