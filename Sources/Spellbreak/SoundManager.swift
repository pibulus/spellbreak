//
//  SoundManager.swift
//  Spellbreak
//
//  Audio playback manager for chimes, ambient sounds, and UI feedback.
//

import AVFoundation
import CoreAudio
import SwiftUI
import AppKit
import os.log

// MARK: - Sound Manager
/// Manages audio playback with error handling, route awareness, and smooth fade effects
class SoundManager: NSObject, ObservableObject, NSSoundDelegate {
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var lastError: Error?
    /// Fired when headphones disconnect during ambient playback so UI state stays synced.
    var onOutputDisconnectedToSpeaker: (() -> Void)?

    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var fadeInTimer: Timer?
    private var fadeOutTimer: Timer?
    private var activeSounds: [NSSound] = []
    private var lastOutputDeviceID: AudioDeviceID = SoundManager.currentDefaultOutputDevice()
    private var outputRouteListenerBlock: AudioObjectPropertyListenerBlock?
    private let logger = Logger(subsystem: "com.pabloalvarado.spellbreak", category: "SoundManager")

    // MARK: - Persisted Properties
    private let defaultVolumePreference: Double = 0.5
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true

    // MARK: - Initialization
    override init() {
        super.init()
        loadAmbientSound()
        installOutputRouteObserver()
    }

    deinit {
        removeOutputRouteObserver()
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        audioPlayer?.stop()
        activeSounds.forEach {
            $0.stop()
            $0.delegate = nil
        }
        activeSounds.removeAll()
    }

    // MARK: - Output Route Awareness
    private static var defaultOutputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    private static func currentDefaultOutputDevice() -> AudioDeviceID {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = defaultOutputAddress
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : AudioDeviceID(kAudioObjectUnknown)
    }

    /// Returns true when the given CoreAudio device is an internal/built-in speaker
    /// (as opposed to headphones, Bluetooth audio, USB DAC, or AirPlay).
    static func isBuiltInSpeaker(_ deviceID: AudioDeviceID) -> Bool {
        guard deviceID != AudioDeviceID(kAudioObjectUnknown) else { return false }

        var transportType: UInt32 = 0
        var transportSize = UInt32(MemoryLayout<UInt32>.size)
        var transportAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let transportErr = AudioObjectGetPropertyData(deviceID, &transportAddr, 0, nil, &transportSize, &transportType)
        guard transportErr == noErr, transportType == kAudioDeviceTransportTypeBuiltIn else {
            return false
        }

        // Check active output data source (e.g. 'ispk' internal speaker vs 'hdpn' headphone jack on older Macs)
        var sourceID: UInt32 = 0
        var sourceSize = UInt32(MemoryLayout<UInt32>.size)
        var sourceAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDataSource,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        if AudioObjectGetPropertyData(deviceID, &sourceAddr, 0, nil, &sourceSize, &sourceID) == noErr {
            // 'hdpn' == 0x6864706e (External Headphones)
            if sourceID == 0x6864706e {
                return false
            }
        }

        // Fallback to CoreAudio device name check (Apple Silicon names separate BuiltIn devices)
        var nameRef: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        if AudioObjectGetPropertyData(deviceID, &nameAddr, 0, nil, &nameSize, &nameRef) == noErr,
           let cfName = nameRef?.takeUnretainedValue() as String? {
            let lower = cfName.lowercased()
            if lower.contains("headphone") {
                return false
            }
        }
        return true
    }

    private func installOutputRouteObserver() {
        var address = Self.defaultOutputAddress
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            let newDevice = Self.currentDefaultOutputDevice()
            let previousDevice = self.lastOutputDeviceID
            self.lastOutputDeviceID = newDevice
            guard newDevice != previousDevice else { return }

            // Unplugging headphones / disconnecting AirPods mid-break falls back to
            // built-in speakers. Silence ambient immediately rather than spilling out loud.
            if self.isPlaying && !Self.isBuiltInSpeaker(previousDevice) && Self.isBuiltInSpeaker(newDevice) {
                self.stopAmbientImmediately()
                self.onOutputDisconnectedToSpeaker?()
            } else if self.isPlaying, let player = self.audioPlayer, !player.isPlaying {
                // Recover cleanly if a Bluetooth/USB route switch stalled AVAudioPlayer
                self.loadAmbientSound()
                self.audioPlayer?.volume = self.ambientTargetVolume
                _ = self.audioPlayer?.play()
            }
        }
        outputRouteListenerBlock = block
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            block
        )
    }

    private func removeOutputRouteObserver() {
        guard let block = outputRouteListenerBlock else { return }
        var address = Self.defaultOutputAddress
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            block
        )
        outputRouteListenerBlock = nil
    }

    // MARK: - Ambient Audio
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
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = ambientTargetVolume
            player.prepareToPlay()
            audioPlayer = player
            lastError = nil
            logger.info("Successfully loaded audio from: \(url.lastPathComponent)")
        } catch {
            let audioError = AudioError.loadFailed(error)
            logger.error("Failed to load audio: \(audioError.localizedDescription)")
            lastError = audioError
        }
    }

    func playAmbient() {
        if audioPlayer == nil {
            loadAmbientSound()
        }
        guard var player = audioPlayer else {
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
        // than restarting the loop from silence.
        if !player.isPlaying {
            player.volume = 0
            if !player.play() {
                // Reload once in case CoreAudio reset the underlying output unit
                loadAmbientSound()
                guard let reloaded = audioPlayer else {
                    lastError = AudioError.playbackFailed
                    isPlaying = false
                    return
                }
                player = reloaded
                player.volume = 0
                guard player.play() else {
                    logger.error("Failed to start audio playback")
                    lastError = AudioError.playbackFailed
                    isPlaying = false
                    return
                }
            }
        }

        lastError = nil
        isPlaying = true

        // Gradually increase volume over about 2 seconds. Read the target each
        // tick so changing the volume cannot leave a stale fade running.
        fadeInTimer = Timer.scheduledCommonTimer(withTimeInterval: 0.05, tolerance: 0.01, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            let targetVolume = self.ambientTargetVolume
            if targetVolume == 0 {
                player.stop()
                player.currentTime = 0
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
        // Idempotent: if a fade-out is already underway, let it finish at its
        // original rate instead of halving fadeStep on duplicate calls.
        if fadeOutTimer != nil { return }
        guard let player = audioPlayer, player.isPlaying else {
            isPlaying = false
            return
        }

        fadeInTimer?.invalidate()
        fadeInTimer = nil

        // Fade out over ~1 second
        let fadeStep = max(player.volume / 20, 0.005)
        fadeOutTimer = Timer.scheduledCommonTimer(withTimeInterval: 0.05, tolerance: 0.01, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            if player.volume > fadeStep {
                player.volume -= fadeStep
            } else {
                player.stop()
                player.currentTime = 0
                player.volume = self.ambientTargetVolume
                player.prepareToPlay()
                self.isPlaying = false
                timer.invalidate()
                self.fadeOutTimer = nil
            }
        }
    }

    /// Stops ambient playback immediately without waiting for the 1s fade (used on
    /// sleep and when headphones unplug so audio never spills out of speakers).
    func stopAmbientImmediately() {
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
        fadeInTimer = nil
        fadeOutTimer = nil
        if let player = audioPlayer {
            player.stop()
            player.currentTime = 0
            player.volume = ambientTargetVolume
        }
        isPlaying = false
    }

    private var ambientTargetVolume: Float {
        Self.outputVolume(preference: defaultVolumePreference, scale: 0.6)
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

        guard Self.outputVolume(preference: defaultVolumePreference, scale: volume) > 0 else { return }

        guard let soundURL = soundURL(named: name) else {
            logger.warning("Sound effect not found: \(name).mp3")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Preference may have changed while playback was queued.
            guard self.soundEffectsEnabled else { return }
            let adjustedVolume = Self.outputVolume(preference: self.defaultVolumePreference, scale: volume)
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

    func playBreakStartChime() {
        playCustomSound(named: "break-start", volume: 0.6)
    }

    /// Play soft completion chime when a break finishes naturally
    func playBreakCompleteChime() {
        playCustomSound(named: "toggle-on", volume: 0.32)
    }

    func playToggleOn() {
        playCustomSound(named: "toggle-on", volume: 0.4)
    }

    func playToggleOff() {
        playCustomSound(named: "toggle-off", volume: 0.4)
    }

    func playButtonPress() {
        playCustomSound(named: "button-press", volume: 0.5)
    }

    func playSliderGrab() {
        playCustomSound(named: "slider-grab", volume: 0.35)
    }

    func playSliderTick() {
        playCustomSound(named: "slider-tick", volume: 0.35)
    }

    func playSliderRelease() {
        playCustomSound(named: "slider-release", volume: 0.35)
    }

    /// Play skip complete sound (using slider release)
    func playSkipComplete() {
        playCustomSound(named: "slider-release", volume: 0.5)
    }
}
