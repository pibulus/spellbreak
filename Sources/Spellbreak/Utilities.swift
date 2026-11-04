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
import IOKit.pwr_mgt

// MARK: - Clamped Timing Bounds
enum SpellbreakLimits {
    static let durationRange: ClosedRange<Double> = 10...180
    static let defaultDurationSec: Double = 20

    static let intervalRange: ClosedRange<Double> = 15...180
    static let defaultIntervalMin: Double = 20

    /// Guards against corrupt or hand-edited UserDefaults (`defaults write` NaN, 0, or 999999)
    /// so Lock mode can never trap a screen for hours and Int casts never overflow.
    static func clampDuration(_ raw: Double) -> Double {
        guard raw.isFinite, raw > 0 else { return defaultDurationSec }
        return min(max(raw, durationRange.lowerBound), durationRange.upperBound)
    }

    static func clampInterval(_ raw: Double) -> Double {
        guard raw.isFinite, raw > 0 else { return defaultIntervalMin }
        return min(max(raw, intervalRange.lowerBound), intervalRange.upperBound)
    }
}

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
        tolerance: TimeInterval = 0,
        repeats: Bool,
        block: @escaping (Timer) -> Void
    ) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
        if tolerance > 0 {
            timer.tolerance = tolerance
        }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
}

extension TimeInterval {
    /// Countdown format ("7:05") shared by the menu bar and popover; safe on NaN/overflow.
    var mmss: String {
        guard isFinite else { return "0:00" }
        let clamped = min(max(self, 0), 359_999)
        let total = Int(clamped)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// Spoken VoiceOver countdown ("7 minutes, 5 seconds" or "18 seconds").
    var spokenDuration: String {
        guard isFinite else { return "0 seconds" }
        let total = Int(min(max(self, 0), 359_999))
        let mins = total / 60
        let secs = total % 60
        let minPart = mins == 1 ? "1 minute" : "\(mins) minutes"
        let secPart = secs == 1 ? "1 second" : "\(secs) seconds"
        if mins > 0 && secs > 0 {
            return "\(minPart), \(secPart)"
        } else if mins > 0 {
            return minPart
        } else {
            return secPart
        }
    }
}

// MARK: - Is the user in the middle of something?
/// A break that lands on top of a fullscreen game or a live video call is not a break,
/// it's an interruption. Same for a film, a presentation, or a meeting.
enum ScreenBusy {
    struct ScreenGeometry {
        let quartzFrame: CGRect
        let notchTopInset: CGFloat
    }

    static func isBusy() -> Bool {
        return aFullscreenAppIsRunning()
            || isMicrophoneInUse()
            || isScreenRecordingOrWatchedVideoActive()
    }

    /// Seconds since the last keyboard, mouse or trackpad event, system-wide. Quartz
    /// answers without Input Monitoring permission: it's a timestamp, never the events.
    static func secondsSinceLastInput() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInputEvent)
    }

    /// Seconds since the last key press anywhere. Same deal: when, never which key.
    static func secondsSinceLastKeystroke() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
    }

    /// True while any mouse or trackpad button is held down (dragging a file, scrubbing
    /// a timeline, resizing a window).
    static func isMouseButtonDown() -> Bool {
        NSEvent.pressedMouseButtons != 0
    }

    /// kCGAnyInputEventType — every event type at once, ~0 in the C header
    private static let anyInputEvent = CGEventType(rawValue: ~0)!

    /// Processes whose whole job is keeping the Mac awake while working — never treat
    /// them as an active film or screen share, or scheduled breaks would stop all day.
    private static let sleepBlockerProcesses: Set<String> = [
        "caffeinate", "amphetamine", "keepingyouawake", "lungomare", "jiggler", "spellbreak"
    ]

    /// Processes (or assertion substrings) that indicate screen recording or screen sharing.
    private static let captureProcessMarkers: [String] = [
        "quicktime", "obs", "loom", "screencapture", "replay", "cleanshot",
        "screenflow", "kap", "descript", "zoom", "teams", "webex", "webrtc"
    ]

    private static let captureReasonMarkers: [String] = [
        "screen capture", "screen recording", "screen share", "screenshare",
        "screencapture", "screen broadcast", "recording", "webrtc"
    ]

    /// Inspects per-process display-sleep assertions (`IOPMCopyAssertionsByProcess`) so
    /// screen recordings / shares always hold breaks, and windowed video playback holds
    /// breaks when the user is watching (hands off mouse + keyboard for 15s+) without
    /// getting tricked by `caffeinate` or mouse-driven browsing next to a muted video.
    static func isScreenRecordingOrWatchedVideoActive() -> Bool {
        var rawAssertions: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&rawAssertions) == kIOReturnSuccess,
              let byPid = rawAssertions?.takeRetainedValue() as? [NSNumber: [[String: Any]]]
        else { return false }

        let handsOffInput = secondsSinceLastInput() >= 15

        for (_, list) in byPid {
            for entry in list {
                let type = (entry["AssertionTrueType"] as? String)
                    ?? (entry["AssertType"] as? String)
                    ?? ""
                guard type == "PreventUserIdleDisplaySleep" || type == "NoDisplaySleepAssertion" else {
                    continue
                }

                let proc = ((entry["Process Name"] as? String) ?? "").lowercased()
                if sleepBlockerProcesses.contains(proc) { continue }

                let reason = ((entry["AssertName"] as? String) ?? "").lowercased()
                let isCapture = captureProcessMarkers.contains { proc.contains($0) }
                    || captureReasonMarkers.contains { reason.contains($0) }

                if isCapture {
                    return true
                }
                if handsOffInput {
                    return true
                }
            }
        }
        return false
    }

    /// Is something keeping the display awake — a playing video, a call? It's how
    /// macOS knows not to dim the screen mid-film, and it's the difference between
    /// a still keyboard and an empty chair: someone gazing at YouTube is in the
    /// trance, not away from it. If powerd won't say, assume nothing is.
    static func displayIsHeldAwake() -> Bool {
        var status: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsStatus(&status) == kIOReturnSuccess,
              let assertions = status?.takeRetainedValue() as? [String: Int] else { return false }
        // kIOPMAssertPreventUserIdleDisplaySleep, and its older name. Both are
        // CFSTR() macros, which Swift can't import, hence the literals.
        return (assertions["PreventUserIdleDisplaySleep"] ?? 0) > 0
            || (assertions["NoDisplaySleepAssertion"] ?? 0) > 0
    }

    static func aFullscreenAppIsRunning() -> Bool {
        // Query WITHOUT .excludeDesktopElements so we can distinguish a maximized window
        // on a regular Desktop Space (where Finder's desktop window is on-screen) from a
        // dedicated macOS Full Screen Space on a notched MacBook (where the window sits
        // below safeAreaInsets.top AND Finder's desktop is NOT on-screen for that display).
        let options: CGWindowListOption = [.optionOnScreenOnly]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return false }
        let primaryHeight = screens[0].frame.height

        let geometries: [ScreenGeometry] = screens.map { screen in
            // Convert AppKit bottom-left origin to Quartz top-left origin so multi-monitor
            // bounds match exact displays instead of only comparing width/height.
            let quartzY = primaryHeight - (screen.frame.origin.y + screen.frame.height)
            let quartzRect = CGRect(
                x: screen.frame.origin.x,
                y: quartzY,
                width: screen.frame.width,
                height: screen.frame.height
            )
            // On notched MacBooks, Full Screen Spaces sit below the camera housing (~33-38pt).
            let menuInset = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
            let notchInset = screen.safeAreaInsets.top > 0
                ? max(screen.safeAreaInsets.top, menuInset)
                : 0
            return ScreenGeometry(quartzFrame: quartzRect, notchTopInset: notchInset)
        }

        return isScreenCoveredByFullscreenWindow(screens: geometries, windows: windows)
    }

    /// Pure geometry evaluator shared with ScreenBusyCheck so both classic full-frame
    /// windows and notched-MacBook Full Screen Spaces can be regression-tested.
    static func isScreenCoveredByFullscreenWindow(
        screens: [ScreenGeometry],
        windows: [[String: Any]]
    ) -> Bool {
        guard !screens.isEmpty else { return false }

        // Track which displays currently have Finder's desktop layer on-screen (meaning
        // that display is on a normal Desktop Space, NOT a dedicated Full Screen Space).
        var desktopSpaceScreenIndices = Set<Int>()
        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer < 0,
                  let owner = window[kCGWindowOwnerName as String] as? String, owner == "Finder",
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat
            else { continue }

            for (idx, screen) in screens.enumerated() {
                if abs(screen.quartzFrame.origin.x - x) <= 2 &&
                   abs(screen.quartzFrame.origin.y - y) <= 2 &&
                   abs(screen.quartzFrame.width - width) <= 2 &&
                   abs(screen.quartzFrame.height - height) <= 2 {
                    desktopSpaceScreenIndices.insert(idx)
                }
            }
        }

        for window in windows {
            // Layer 0 is the normal document layer. Our own overlay sits far above it,
            // as do the menu bar and the dock, so this skips the system's furniture.
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat,
                  let owner = window[kCGWindowOwnerName as String] as? String,
                  owner != "Spellbreak"
            else { continue }

            for (idx, screen) in screens.enumerated() {
                let frame = screen.quartzFrame
                let matchesX = abs(frame.origin.x - x) <= 2 && abs(frame.width - width) <= 2
                guard matchesX else { continue }

                // 1. Classic full-frame window (borderless game, Keynote presentation, video player)
                if abs(frame.origin.y - y) <= 2 && abs(frame.height - height) <= 2 {
                    return true
                }

                // 2. Notched MacBook native Full Screen Space: macOS places the window right below
                //    the camera housing (Y ≈ frame.minY + notchTopInset, Height ≈ frame.height - notchTopInset)
                //    on a dedicated Space where Finder's desktop is NOT on-screen.
                if screen.notchTopInset > 0 && !desktopSpaceScreenIndices.contains(idx) {
                    let expectedY = frame.origin.y + screen.notchTopInset
                    let expectedH = frame.height - screen.notchTopInset
                    if abs(expectedY - y) <= 3 && abs(expectedH - height) <= 3 {
                        return true
                    }
                }
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
