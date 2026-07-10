//
//  Utilities.swift
//  Spellbreak
//
//  Small shared helpers used across the app.
//

import Foundation
import SwiftUI

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
