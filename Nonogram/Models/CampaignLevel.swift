import Foundation
import UIKit

/// A single level node along the campaign progression trail.
public struct CampaignLevel: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let seed: UInt64
    public let rows: Int
    public let cols: Int
    public let title: String
    public let subtitle: String

    public var theme: ChapterTheme {
        ChapterTheme.theme(for: id)
    }

    public init(
        id: Int,
        seed: UInt64,
        rows: Int,
        cols: Int,
        title: String,
        subtitle: String
    ) {
        self.id = id
        self.seed = seed
        self.rows = rows
        self.cols = cols
        self.title = title
        self.subtitle = subtitle
    }
}

/// Visual theme palette for the game world.
public enum ChapterTheme: String, CaseIterable, Identifiable, Codable, Sendable {
    case meadow // Lush green meadows and warm dirt road
    case autumn // Golden autumn leaves and stone trail
    case winter // Snow and icy blue trail

    public var id: String { rawValue }

    /// Automatic theme per 20 levels:
    /// - 1...20: Meadow (Pradaria)
    /// - 21...40: Autumn (Bosque Dourado)
    /// - 41...60: Winter (Inverno Nevado)
    /// - Cycles forward for infinite progression
    public static func theme(for levelId: Int) -> ChapterTheme {
        let chapterIndex = (max(1, levelId) - 1) / 20
        let sequence: [ChapterTheme] = [.meadow, .autumn, .winter]
        return sequence[chapterIndex % sequence.count]
    }

    public static func chapterNumber(for levelId: Int) -> Int {
        ((max(1, levelId) - 1) / 20) + 1
    }

    public static func chapterTitle(for levelId: Int) -> String {
        let num = chapterNumber(for: levelId)
        let theme = theme(for: levelId)
        return "Capítulo \(num): \(theme.title)"
    }

    public var title: String {
        switch self {
        case .meadow: return "Pradaria"
        case .autumn: return "Bosque Dourado"
        case .winter: return "Inverno Nevado"
        }
    }

    public var systemIcon: String {
        switch self {
        case .meadow: return "leaf.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }

    public var backgroundGradientColors: [String] {
        switch self {
        case .meadow:
            return ["#88D49E", "#5FB77E", "#4BA36A"]
        case .autumn:
            return ["#F6D365", "#FDA085", "#D35400"]
        case .winter:
            return ["#A1C4FD", "#C2E9FB", "#E0F2FE"]
        }
    }

    public var appTheme: any AppTheme {
        switch self {
        case .meadow:
            return MeadowTheme()
        case .autumn:
            return AutumnTheme()
        case .winter:
            return WinterTheme()
        }
    }
}

/// Infinite level generator creating device-optimized puzzle dimensions in 20-level batches:
/// - iPad: Square aspect ratio (1:1)
/// - iPhone: Vertical aspect ratio (~3:2, rows > cols)
public struct CampaignLevelGenerator {
    public static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    public static func level(for id: Int, isPad: Bool = isIPad) -> CampaignLevel {
        let rows: Int
        let cols: Int
        let theme = ChapterTheme.theme(for: id)
        let offset = (max(1, id) - 1) % 20 // 0 to 19

        if isPad {
            // Square progression for iPad (1:1)
            switch offset {
            case 0...3:
                rows = 4; cols = 4
            case 4...8:
                rows = 5; cols = 5
            case 9...13:
                rows = 6; cols = 6
            case 14...17:
                rows = 7; cols = 7
            default:
                rows = 8; cols = 8
            }
        } else {
            // Vertical progression for iPhone (~3:2 aspect ratio: rows > cols)
            switch offset {
            case 0...3:
                rows = 5; cols = 3
            case 4...8:
                rows = 6; cols = 4 // 6:4 = 3:2
            case 9...13:
                rows = 8; cols = 5
            case 14...17:
                rows = 9; cols = 6 // 9:6 = 3:2
            default:
                rows = 11; cols = 7
            }
        }

        return CampaignLevel(
            id: id,
            seed: UInt64(1000 + id * 7919),
            rows: rows,
            cols: cols,
            title: "Fase \(id)",
            subtitle: theme.title
        )
    }

    /// Returns all levels up to the current unlocked batch of 20 for the active device idiom.
    public static func levelsForProgress(unlockedLevelIndex: Int, isPad: Bool = isIPad) -> [CampaignLevel] {
        let batchIndex = (max(1, unlockedLevelIndex) - 1) / 20
        let totalCount = max(20, (batchIndex + 1) * 20)
        return (1...totalCount).map { level(for: $0, isPad: isPad) }
    }
}
