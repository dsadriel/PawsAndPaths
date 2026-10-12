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
    case winter // Snow and icy blue trail
    case autumn // Golden autumn leaves and stone trail

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .meadow: return "Pradaria"
        case .winter: return "Inverno Nevado"
        case .autumn: return "Bosque Dourado"
        }
    }

    public var systemIcon: String {
        switch self {
        case .meadow: return "leaf.fill"
        case .winter: return "snowflake"
        case .autumn: return "wind"
        }
    }

    public var backgroundGradientColors: [String] {
        switch self {
        case .meadow:
            return ["#88D49E", "#5FB77E", "#4BA36A"]
        case .winter:
            return ["#A1C4FD", "#C2E9FB", "#E0F2FE"]
        case .autumn:
            return ["#F6D365", "#FDA085", "#D35400"]
        }
    }

    public var appTheme: any AppTheme {
        switch self {
        case .meadow:
            return MeadowTheme()
        case .winter:
            return WinterTheme()
        case .autumn:
            return AutumnTheme()
        }
    }
}

/// Infinite level generator creating device-optimized puzzle dimensions in 15-level batches:
/// - iPad: Square aspect ratio (1:1)
/// - iPhone: Vertical aspect ratio (~3:2, rows > cols)
public struct CampaignLevelGenerator {
    public static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    public static func level(for id: Int, isPad: Bool = isIPad) -> CampaignLevel {
        let rows: Int
        let cols: Int
        let subtitle: String

        if isPad {
            // Square progression for iPad (1:1)
            if id <= 3 {
                rows = 4
                cols = 4
                subtitle = "Primeiros Passos"
            } else if id <= 8 {
                rows = 5
                cols = 5
                subtitle = "Trilha do Jardim"
            } else if id <= 15 {
                rows = 6
                cols = 6
                subtitle = "Passeio pelo Bosque"
            } else if id <= 25 {
                rows = 7
                cols = 7
                subtitle = "Caminho das Pedras"
            } else if id <= 40 {
                rows = 8
                cols = 8
                subtitle = "Desafio do Bosque"
            } else {
                let cycle = id % 4
                switch cycle {
                case 0:
                    rows = 7; cols = 7; subtitle = "Aventura Infinita"
                case 1:
                    rows = 8; cols = 8; subtitle = "Labirinto Secreto"
                case 2:
                    rows = 9; cols = 9; subtitle = "Desafio dos Mestres"
                default:
                    rows = 8; cols = 8; subtitle = "Caminho Estrelado"
                }
            }
        } else {
            // Vertical progression for iPhone (~3:2 aspect ratio: rows > cols)
            if id <= 3 {
                rows = 5
                cols = 3
                subtitle = "Primeiros Passos"
            } else if id <= 8 {
                rows = 6
                cols = 4 // 6:4 = 3:2
                subtitle = "Trilha do Jardim"
            } else if id <= 15 {
                rows = 8
                cols = 5
                subtitle = "Passeio pelo Bosque"
            } else if id <= 25 {
                rows = 9
                cols = 6 // 9:6 = 3:2
                subtitle = "Caminho das Pedras"
            } else if id <= 40 {
                rows = 11
                cols = 7
                subtitle = "Desafio do Bosque"
            } else {
                let cycle = id % 4
                switch cycle {
                case 0:
                    rows = 9; cols = 6; subtitle = "Aventura Infinita" // 3:2
                case 1:
                    rows = 10; cols = 7; subtitle = "Labirinto Secreto"
                case 2:
                    rows = 12; cols = 8; subtitle = "Desafio dos Mestres" // 3:2
                default:
                    rows = 11; cols = 7; subtitle = "Caminho Estrelado"
                }
            }
        }

        return CampaignLevel(
            id: id,
            seed: UInt64(1000 + id * 7919),
            rows: rows,
            cols: cols,
            title: "Fase \(id)",
            subtitle: subtitle
        )
    }

    /// Returns all levels up to the current unlocked batch of 15 for the active device idiom.
    public static func levelsForProgress(unlockedLevelIndex: Int, isPad: Bool = isIPad) -> [CampaignLevel] {
        let batchIndex = unlockedLevelIndex / 15
        let totalCount = max(15, (batchIndex + 1) * 15)
        return (1...totalCount).map { level(for: $0, isPad: isPad) }
    }
}
