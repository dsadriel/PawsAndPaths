import AVFoundation
import UIKit

/// Manages cozy audio feedback and sound effects for Paws & Paths.
@MainActor
public final class SoundManager {
    public static let shared = SoundManager()

    public var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "paws_sound_muted") }
        set { UserDefaults.standard.set(newValue, forKey: "paws_sound_muted") }
    }

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
        preloadSounds()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundManager: Failed to configure ambient audio session: \(error)")
        }
    }

    private func preloadSounds() {
        let soundNames = ["sfx_tile_click", "sfx_cross", "sfx_clue_chime", "sfx_victory", "sfx_button"]
        for name in soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[name] = player
                } catch {
                    print("SoundManager: Could not preload \(name).wav: \(error)")
                }
            }
        }
    }

    public func play(_ name: String, volume: Float = 1.0) {
        guard !isMuted else { return }

        if let player = players[name] {
            player.volume = volume
            player.currentTime = 0
            player.play()
        } else if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = volume
                player.play()
                players[name] = player
            } catch {
                print("SoundManager: Error playing \(name): \(error)")
            }
        }
    }

    /// Sound for placing a path / wooden track
    public func pathPlaced() {
        play("sfx_tile_click", volume: 0.85)
    }

    /// Sound for marking a cross tile
    public func crossPlaced() {
        play("sfx_cross", volume: 0.6)
    }

    /// Gentle wind chime when a clue line/column is completed
    public func clueSatisfied() {
        play("sfx_clue_chime", volume: 0.75)
    }

    /// Joyful harp arpeggio when level is won
    public func victory() {
        play("sfx_victory", volume: 0.9)
    }

    /// Button tap pop
    public func buttonPress() {
        play("sfx_button", volume: 0.5)
    }
}
