import SwiftUI

/// Vector paved path segment that cleanly connects to adjacent neighbors using continuous, unbroken lines.
public struct PavedTrackView: View {
    @Environment(\.appTheme) private var appTheme

    public let connections: TileConnection
    public let isStart: Bool
    public let isEnd: Bool
    public let hasMascot: Bool
    public let size: CGFloat

    public init(
        connections: TileConnection,
        isStart: Bool,
        isEnd: Bool,
        hasMascot: Bool,
        size: CGFloat
    ) {
        self.connections = connections
        self.isStart = isStart
        self.isEnd = isEnd
        self.hasMascot = hasMascot
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Track base bed
            RoundedRectangle(cornerRadius: max(3, size * 0.18))
                .fill(Theme.Colors.creamPanel)
                .shadow(color: Theme.Colors.woodDark.opacity(0.12), radius: 1, x: 0, y: 1)

            let trackWidth = max(7, size * 0.38)
            let trackColor = appTheme.colors.track
            let midX = size / 2
            let midY = size / 2
            // Bleed extends beyond tile edges by 2.5pt to seamlessly bridge the 3pt grid spacing
            let bleed: CGFloat = 2.5

            // Seamless continuous path segments connecting across tile boundaries
            Path { path in
                let westPt = CGPoint(x: -bleed, y: midY)
                let eastPt = CGPoint(x: size + bleed, y: midY)
                let northPt = CGPoint(x: midX, y: -bleed)
                let southPt = CGPoint(x: midX, y: size + bleed)
                let centerPt = CGPoint(x: midX, y: midY)

                let hasW = connections.contains(.west)
                let hasE = connections.contains(.east)
                let hasN = connections.contains(.north)
                let hasS = connections.contains(.south)

                // 1. Straight horizontal road
                if hasW && hasE && !hasN && !hasS {
                    path.move(to: westPt)
                    path.addLine(to: eastPt)
                }
                // 2. Straight vertical road
                else if hasN && hasS && !hasW && !hasE {
                    path.move(to: northPt)
                    path.addLine(to: southPt)
                }
                // 3. Corners & Multi-way junctions
                else {
                    if hasW {
                        path.move(to: westPt)
                        path.addLine(to: centerPt)
                    }
                    if hasE {
                        path.move(to: eastPt)
                        path.addLine(to: centerPt)
                    }
                    if hasN {
                        path.move(to: northPt)
                        path.addLine(to: centerPt)
                    }
                    if hasS {
                        path.move(to: southPt)
                        path.addLine(to: centerPt)
                    }
                }
            }
            .stroke(trackColor, style: StrokeStyle(lineWidth: trackWidth, lineCap: .square, lineJoin: .round))

            // Start tile: cozy pawprint marker
            if isStart {
                Circle()
                    .fill(Theme.Colors.creamSurface)
                    .frame(width: trackWidth * 1.25, height: trackWidth * 1.25)
                    .shadow(color: Theme.Colors.woodDark.opacity(0.15), radius: 1)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.38))
                    .foregroundColor(Theme.Colors.inkPrimary.opacity(0.70))
            }

            // End tile: yarn ball destination
            if isEnd {
                Image(appTheme.assets.targetItemAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.78, height: size * 0.78)
                    .shadow(color: Theme.Colors.woodDark.opacity(0.25), radius: 2, y: 1)
            }
        }
        .frame(width: size, height: size)
    }
}
