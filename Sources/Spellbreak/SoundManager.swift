//
//  SoundManager.swift
//  Spellbreak
//
//  Audio playback manager for chimes, ambient sounds, and UI feedback.
//

import AVFoundation
import SwiftUI
import AppKit
import os.log

// MARK: - Sound Manager
/// Manages audio playback with error handling and smooth fade effects
class SoundManager: NSObject, ObservableObject, NSSoundDelegate {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var fadeInTimer: Timer?
    private var fadeOutTimer: Timer?
    private var activeSounds: [NSSound] = []
    private let logger = Logger(subsystem: "com.pabloalvarado.spellbreak", category: "SoundManager")
    
    // MARK: - Persisted Properties
    @AppStorage("soundVolume") private var soundVolume: Double = 0.5
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadAmbientSound()
    }
    
    deinit {
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        audioPlayer?.stop()
        activeSounds.forEach {
            $0.stop()
            $0.delegate = nil
        }
        activeSounds.removeAll()
    }
    
    // MARK: - Private Methods
    private func loadAmbientSound() {
        if let soundURL = ambientSoundURL() {
            loadAudioFromURL(soundURL)
            return
        }

        let error = AudioError.fileNotFound("ambient_loop.m4a")
        logger.error("Failed to find audio file: \(error.localizedDescription)")
        lastError = error
    }

    private func ambientSoundURL() -> URL? {
        for ext in ["m4a", "mp3"] {
            if let url = Bundle.main.url(forResource: "ambient_loop", withExtension: ext, subdirectory: "Sounds") {
                return url
            }

            if let url = Bundle.main.url(forResource: "ambient_loop", withExtension: ext) {
                return url
            }
        }

        return nil
    }
    
    private func loadAudioFromURL(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.volume = ambientTargetVolume
            audioPlayer?.prepareToPlay()
            lastError = nil
            logger.info("Successfully loaded audio from: \(url.lastPathComponent)")
        } catch {
            let audioError = AudioError.loadFailed(error)
            logger.error("Failed to load audio: \(audioError.localizedDescription)")
            lastError = audioError
        }
    }
    
    func playAmbient() {
        guard let player = audioPlayer else {
            logger.warning("Audio player not available")
            return
        }
        guard ambientTargetVolume > 0 else { return }

        // Cancel any existing fade timers
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        fadeInTimer = nil
        fadeOutTimer = nil

        // A second tap during fade-out resumes from its current level, rather
        // than restarting the loop from silence. Leave output routing to macOS
        // rather than pinning a device (especially when headphones change).
        if !player.isPlaying {
            player.volume = 0
            guard player.play() else {
                logger.error("Failed to start audio playback")
                isPlaying = false
                return
            }
        }

        isPlaying = true

        // Gradually increase volume over about 2 seconds. Read the target each
        // tick so changing the volume cannot leave a stale fade running.
        fadeInTimer = Timer.scheduledCommonTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            let targetVolume = self.ambientTargetVolume
            if targetVolume == 0 {
                player.stop()
                self.isPlaying = false
                timer.invalidate()
                self.fadeInTimer = nil
                return
            }
            if player.volume < targetVolume {
                player.volume = min(player.volume + targetVolume / 40, targetVolume)
            } else {
                player.volume = targetVolume
                timer.invalidate()
                self.fadeInTimer = nil
            }
        }
    }
    
    func stopAmbient() {
        guard let player = audioPlayer, player.isPlaying else { return }

        // Cancel any existing fade timers
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        fadeInTimer = nil
        fadeOutTimer = nil

        // Fade out over 1 second
        let fadeStep = max(player.volume / 20, 0.001)
        fadeOutTimer = Timer.scheduledCommonTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            if player.volume > fadeStep {
                player.volume -= fadeStep
            } else {
                player.stop()
                player.volume = self.ambientTargetVolume  // Reset for next time
                self.isPlaying = false
                timer.invalidate()
                self.fadeOutTimer = nil
            }
        }
    }

    /// Apply a changed preference to an already-playing loop. A running fade
    /// owns the volume until it finishes; the next tick reads the new target.
    func updateAmbientVolume() {
        guard let player = audioPlayer, player.isPlaying else { return }
        if ambientTargetVolume == 0 {
            fadeInTimer?.invalidate()
            fadeOutTimer?.invalidate()
            fadeInTimer = nil
            fadeOutTimer = nil
            player.stop()
            isPlaying = false
        } else if fadeInTimer == nil && fadeOutTimer == nil {
            player.volume = ambientTargetVolume
        }
    }

    private var ambientTargetVolume: Float {
        Self.outputVolume(preference: soundVolume, scale: 0.6)
    }

    /// A corrupt or out-of-range stored preference must never produce a blast
    /// (or NaN) on a freshly connected output, including headphones.
    static func outputVolume(preference: Double, scale: Float) -> Float {
        guard preference.isFinite, scale.isFinite else { return 0 }
        return Float(min(max(preference, 0), 1)) * min(max(scale, 0), 1)
    }
    
    // MARK: - Sound Effects
    
    /// Helper to play custom bundled sounds
    private func playCustomSound(named name: String, volume: Float = 0.5) {
        guard soundEffectsEnabled else { return }

        guard Self.outputVolume(preference: soundVolume, scale: volume) > 0 else { return }

        guard let soundURL = soundURL(named: name) else {
            logger.warning("Sound effect not found: \(name).mp3")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Preference may have changed while playback was queued.
            guard self.soundEffectsEnabled else { return }
            let adjustedVolume = Self.outputVolume(preference: self.soundVolume, scale: volume)
            guard adjustedVolume > 0 else { return }
            guard let sound = NSSound(contentsOf: soundURL, byReference: false) else {
                self.logger.warning("Failed to load sound effect: \(name).mp3")
                return
            }

            sound.volume = adjustedVolume
            sound.delegate = self
            self.activeSounds.append(sound)

            if !sound.play() {
                self.activeSounds.removeAll { $0 === sound }
                self.logger.warning("Failed to play sound effect: \(name).mp3")
            }
        }
    }

    private func soundURL(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
    }

    func sound(_ sound: NSSound, didFinishPlaying finished: Bool) {
        if Thread.isMainThread {
            activeSounds.removeAll { $0 === sound }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.activeSounds.removeAll { $0 === sound }
            }
        }
    }
    
    /// Play break start chime
    func playBreakStartChime() {
        playCustomSound(named: "break-start", volume: 0.6)
    }
    
    /// Play toggle on sound
    func playToggleOn() {
        playCustomSound(named: "toggle-on", volume: 0.4)
    }
    
    /// Play toggle off sound
    func playToggleOff() {
        playCustomSound(named: "toggle-off", volume: 0.4)
    }
    
    /// Play button press sound
    func playButtonPress() {
        playCustomSound(named: "button-press", volume: 0.5)
    }

    /// Play slider grab sound
    func playSliderGrab() {
        playCustomSound(named: "slider-grab", volume: 0.35)
    }

    /// Play slider movement tick
    func playSliderTick() {
        playCustomSound(named: "slider-tick", volume: 0.25)
    }

    /// Play slider release sound
    func playSliderRelease() {
        playCustomSound(named: "slider-release", volume: 0.35)
    }
    
    /// Play skip complete sound (using slider release)
    func playSkipComplete() {
        playCustomSound(named: "slider-release", volume: 0.5)
    }
}
