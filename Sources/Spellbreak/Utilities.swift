//
//  Utilities.swift
//  Spellbreak
//
//  Small shared helpers used across the app.
//

import Foundation
import SwiftUI
import AppKit

// MARK: - Palette
extension Color {
    /// Spellbreak's signature gradient colors
    static let spellPink = Color(red: 0.95, green: 0.4, blue: 0.8)
    static let spellCoral = Color(red: 1.0, green: 0.6, blue: 0.5)
    static let spellPeach = Color(red: 1.0, green: 0.7, blue: 0.5)
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
/// A break that lands on top of a fullscreen game is not a break, it's a death. Same
/// for a film, a presentation, or a call — anything the user deliberately made
/// fullscreen is a statement that they do not want to be interrupted right now.
///
/// Detection is deliberately dumb and public-API only: ask the window server for the
/// on-screen windows at the normal layer, and see if any of them exactly covers a
/// whole screen. A fullscreen app owns its whole display; a merely-maximised window
/// still leaves the menu bar, so its frame is shorter than the screen's.
enum ScreenBusy {
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
}
