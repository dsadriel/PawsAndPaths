import SwiftUI

struct ContentView: View {
    private var screenMode: String {
        if let idx = CommandLine.arguments.firstIndex(of: "-screen"), idx + 1 < CommandLine.arguments.count {
            return CommandLine.arguments[idx + 1]
        }
        return "map"
    }

    private var levelArg: Int {
        if let idx = CommandLine.arguments.firstIndex(of: "-level"), idx + 1 < CommandLine.arguments.count,
           let parsed = Int(CommandLine.arguments[idx + 1]) {
            return parsed
        }
        return 1
    }

    var body: some View {
        switch screenMode {
        case "game":
            GameView(campaignLevel: CampaignLevelGenerator.level(for: levelArg))
        case "hintOverlay":
            GameView(campaignLevel: CampaignLevelGenerator.level(for: levelArg), initialOverlay: .hint)
        case "insufficientOverlay":
            GameView(campaignLevel: CampaignLevelGenerator.level(for: levelArg), initialOverlay: .insufficientCoins)
        case "victory":
            GameView(campaignLevel: CampaignLevelGenerator.level(for: levelArg), initialOverlay: .victory)
        default:
            CampaignMapView()
        }
    }
}

#Preview {
    ContentView()
}
