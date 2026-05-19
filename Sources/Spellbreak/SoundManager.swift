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
            let volume = Float(soundVolume * 0.6)
            audioPlayer?.volume = volume
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

        // Cancel any existing fade timers
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()

        // Fade in
        player.volume = 0
        let success = player.play()
        if !success {
            logger.error("Failed to start audio playback")
            return
        }

        isPlaying = true

        // Gradually increase volume over 2 seconds
        let targetVolume = Float(soundVolume * 0.6)
        fadeInTimer = scheduleTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            if player.volume < targetVolume {
                player.volume += Float(targetVolume / 40) // 40 steps = 2 seconds
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

        // Fade out over 1 second
        let fadeStep = max(player.volume / 20, 0.001)
        fadeOutTimer = scheduleTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            if player.volume > fadeStep {
                player.volume -= fadeStep
            } else {
                player.stop()
                player.volume = Float(self.soundVolume * 0.6)  // Reset for next time
                self.isPlaying = false
                timer.invalidate()
                self.fadeOutTimer = nil
            }
        }
    }
    
    // MARK: - Sound Effects
    
    /// Helper to play custom bundled sounds
    private func playCustomSound(named name: String, volume: Float = 0.5) {
        guard soundEffectsEnabled else { return }

        let adjustedVolume = clampedVolume(volume * Float(soundVolume))
        guard adjustedVolume > 0 else { return }

        guard let soundURL = soundURL(named: name) else {
            logger.warning("Sound effect not found: \(name).mp3")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
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

    private func clampedVolume(_ volume: Float) -> Float {
        min(max(volume, 0), 1)
    }

    private func scheduleTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
        RunLoop.main.add(timer, forMode: .common)
        return timer
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
    
    /// Play hold feedback sound (using slider tick)
    func playHoldFeedback() {
        playCustomSound(named: "slider-tick", volume: 0.3)
    }
    
    /// Play skip complete sound (using slider release)
    func playSkipComplete() {
        playCustomSound(named: "slider-release", volume: 0.5)
    }
    
    /// Play typewriter keystroke (using slider tick quietly)
    func playTypewriterKey() {
        playCustomSound(named: "slider-tick", volume: 0.2)
    }
    
    /// Play milestone reached sound (using break start)
    func playMilestone() {
        playCustomSound(named: "break-start", volume: 0.7)
    }
}
