//
//  AppDelegate.swift
//  Spellbreak
//
//  App delegate to manage the status bar controller
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var appState: AppState!
    var soundManager: SoundManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon since we're a menu bar app
        NSApp.setActivationPolicy(.accessory)

        soundManager = SoundManager()
        appState = AppState()
        appState.soundManager = soundManager

        // Create and configure status bar controller immediately
        statusBarController = StatusBarController()
        statusBarController.configure(with: appState)

        // First launch: we're a faceless menu bar app, so show Preferences
        // once so new users see *something* (and can hit Start / Test Break)
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            defaults.set(true, forKey: "hasLaunchedBefore")
            appState.showPreferences()
        }
    }
}
