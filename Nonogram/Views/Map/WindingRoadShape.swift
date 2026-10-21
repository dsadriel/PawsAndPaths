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
    public let points: [CGPoint]

    public init(points: [CGPoint]) {
        self.points = points
    }

    private struct RoadSegment: Identifiable {
        let id: Int
        let points: [CGPoint]
        let theme: ChapterTheme
    }

    private var segments: [RoadSegment] {
        guard points.count >= 2 else { return [] }
        var result: [RoadSegment] = []
        let chunkSize = 20
        var startIndex = 0
        var chapterIndex = 0

        while startIndex < points.count - 1 {
            let endIndex = min(startIndex + chunkSize, points.count - 1)
            let segmentPoints = Array(points[startIndex...endIndex])
            // The segment leads into the next chapter at boundary
            let chapterLevelId = startIndex == 0 ? 1 : (startIndex + 2)
            result.append(
                RoadSegment(
                    id: chapterIndex,
                    points: segmentPoints,
                    theme: ChapterTheme.theme(for: chapterLevelId)
                )
            )
            if endIndex >= points.count - 1 {
                break
            }
            startIndex = endIndex
            chapterIndex += 1
        }
        return result
    }

    public var body: some View {
        ZStack {
            ForEach(segments) { segment in
                let segTheme = segment.theme.appTheme
                ZStack {
                    // Road grass/embankment border matching chapter theme
                    WindingRoadShape(points: segment.points)
                        .stroke(
                            segTheme.colors.track.opacity(0.45),
                            style: StrokeStyle(lineWidth: 46, lineCap: .round, lineJoin: .round)
                        )

                    // Inner road surface
                    WindingRoadShape(points: segment.points)
                        .stroke(
                            Color.white.opacity(0.85),
                            style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round)
                        )

                    // Road surface theme tint
                    WindingRoadShape(points: segment.points)
                        .stroke(
                            segTheme.colors.track.opacity(0.22),
                            style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round)
                        )

                    // Decorative center stepping stone track
                    WindingRoadShape(points: segment.points)
                        .stroke(
                            segTheme.colors.track.opacity(0.70),
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round, dash: [6, 8])
                        )
                }
            }
        }
    }
}
