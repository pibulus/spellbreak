//
//  Utilities.swift
//  Spellbreak
//
//  Small shared helpers used across the app.
//

import Foundation
import SwiftUI
import AppKit
import CoreAudio
import AudioToolbox

// MARK: - Palette
extension Color {
    /// Spellbreak's signature gradient colors
    static let spellPink = Color(red: 0.95, green: 0.4, blue: 0.8)
    static let spellCoral = Color(red: 1.0, green: 0.6, blue: 0.5)
    static let spellPeach = Color(red: 1.0, green: 0.7, blue: 0.5)

    /// Warm near-white for break text and overlay chrome. Absolute white is never
    /// used anywhere in the fleet — on a dark aurora it reads as a hole punched in
    /// the screen, where cream reads as light.
    static let spellCream = Color(red: 0.984, green: 0.953, blue: 0.906)

    /// Warm near-black for ink on light chips. Absolute black is as banned as
    /// absolute white, and on a cream chip it reads as a hole rather than as type.
    static let spellInk = Color(red: 0.118, green: 0.090, blue: 0.078)
}

extension Timer {
    /// Creates a timer on the main run loop in .common mode so it keeps
    /// firing during event tracking (open menus, slider drags).
    static func scheduledCommonTimer(
        withTimeInterval interval: TimeInterval,
        repeats: Bool,
        block: @escaping (Timer) -> Void
    ) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
}

extension TimeInterval {
    /// Countdown format ("7:05") shared by the menu bar and popover
    var mmss: String {
        let total = Int(self)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Is the user in the middle of something?
/// A break that lands on top of a fullscreen game or a live video call is not a break,
/// it's an interruption. Same for a film, a presentation, or a meeting.
enum ScreenBusy {
    static func isBusy() -> Bool {
        return aFullscreenAppIsRunning() || isMicrophoneInUse()
    }

    static func aFullscreenAppIsRunning() -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        let screenFrames = NSScreen.screens.map { $0.frame }
        guard !screenFrames.isEmpty else { return false }

        for window in windows {
            // Layer 0 is the normal document layer. Our own overlay sits far above it,
            // as do the menu bar and the dock, so this skips the system's furniture.
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat,
                  let owner = window[kCGWindowOwnerName as String] as? String,
                  owner != "Spellbreak"
            else { continue }

            // Any screen this window covers entirely means someone went fullscreen.
            // 1pt of slack because window bounds and screen frames disagree at the edges.
            if screenFrames.contains(where: {
                abs($0.width - width) <= 1 && abs($0.height - height) <= 1
            }) {
                return true
            }
        }

        return false
    }

    /// Checks if the default audio input device (mic) is actively capturing audio for any app
    /// (e.g. Zoom, Google Meet in browser, Microsoft Teams, FaceTime, Slack huddle, Discord).
    static func isMicrophoneInUse() -> Bool {
        var defaultInputDeviceID = AudioObjectID(kAudioObjectUnknown)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize = UInt32(MemoryLayout<AudioObjectID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultInputDeviceID
        )
        guard status == noErr, defaultInputDeviceID != kAudioObjectUnknown else {
            return false
        }

        var isRunning: UInt32 = 0
        propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        propertySize = UInt32(MemoryLayout<UInt32>.size)

        let isRunningStatus = AudioObjectGetPropertyData(
            defaultInputDeviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &isRunning
        )
        return isRunningStatus == noErr && isRunning != 0
    }
}
