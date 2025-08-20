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
class SoundManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private let logger = Logger(subsystem: "com.eyedrop", category: "SoundManager")
    
    // MARK: - Persisted Properties
    @AppStorage("soundVolume") private var soundVolume: Double = 0.5
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true
    
    // MARK: - Initialization
    init() {
        loadAmbientSound()
    }
    
    deinit {
        fadeTimer?.invalidate()
    }
    
    // MARK: - Private Methods
    private func loadAmbientSound() {
        // Try with subdirectory first
        if let soundURL = Bundle.main.url(forResource: "ambient_loop", withExtension: "mp3", subdirectory: "Sounds") {
            loadAudioFromURL(soundURL)
            return
        }
        
        // Try without subdirectory
        if let soundURL = Bundle.main.url(forResource: "ambient_loop", withExtension: "mp3") {
            loadAudioFromURL(soundURL)
            return
        }
        
        // Try in Sounds subdirectory with different path
        if let soundURL = Bundle.main.url(forResource: "Sounds/ambient_loop", withExtension: "mp3") {
            loadAudioFromURL(soundURL)
            return
        }
        
        let error = AudioError.fileNotFound("ambient_loop.mp3")
        logger.error("Failed to find audio file: \(error.localizedDescription)")
        lastError = error
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
        
        do {
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
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if player.volume < targetVolume {
                    player.volume += Float(targetVolume / 40) // 40 steps = 2 seconds
                } else {
                    player.volume = targetVolume
                    timer.invalidate()
                }
            }
        }
    }
    
    func stopAmbient() {
        guard let player = audioPlayer, player.isPlaying else { return }
        
        // Fade out over 1 second
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if player.volume > 0 {
                player.volume -= 0.015
            } else {
                player.stop()
                player.volume = Float(self.soundVolume * 0.6)  // Reset for next time
                self.isPlaying = false
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Sound Effects
    
    /// Helper to play custom bundled sounds
    private func playCustomSound(named name: String, volume: Float = 0.5) {
        guard soundEffectsEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            // Try to load from Sounds subdirectory first
            if let soundURL = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds") {
                if let sound = NSSound(contentsOf: soundURL, byReference: false) {
                    sound.volume = volume
                    sound.play()
                    return
                }
            }
            
            // Fallback: try without subdirectory
            if let soundURL = Bundle.main.url(forResource: name, withExtension: "mp3") {
                if let sound = NSSound(contentsOf: soundURL, byReference: false) {
                    sound.volume = volume
                    sound.play()
                }
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