import SwiftUI

/// Draws a continuous smooth Bezier curve through a series of waypoint coordinates.
public struct WindingRoadShape: Shape {
    public let points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        let count = points.count
        let tension: CGFloat = 0.26

        for i in 0..<(count - 1) {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = (i + 2 < count) ? points[i + 2] : p2

            // Natural Catmull-Rom tangents
            let c1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension,
                y: p1.y + (p2.y - p0.y) * tension
            )
            let c2 = CGPoint(
                x: p2.x - (p3.x - p1.x) * tension,
                y: p2.y - (p3.y - p1.y) * tension
            )

            path.addCurve(to: p2, control1: c1, control2: c2)
        }

        return path
    }
}

/// Complete styled winding road with outer curb, inner dirt surface, and decorative center track.
public struct StyledWindingRoadView: View {
    @Environment(\.appTheme) private var appTheme
    public let points: [CGPoint]

    public var body: some View {
        ZStack {
            // Road grass embankment border
            WindingRoadShape(points: points)
                .stroke(
                    appTheme.colors.track.opacity(0.45),
                    style: StrokeStyle(lineWidth: 46, lineCap: .round, lineJoin: .round)
                )

            // Inner road surface
            WindingRoadShape(points: points)
                .stroke(
                    Color.white.opacity(0.85),
                    style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round)
                )

            // Road surface theme tint
            WindingRoadShape(points: points)
                .stroke(
                    appTheme.colors.track.opacity(0.22),
                    style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round)
                )

            // Decorative center stepping stone track
            WindingRoadShape(points: points)
                .stroke(
                    appTheme.colors.track.opacity(0.70),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round, dash: [6, 8])
                )
        }
    }
}
