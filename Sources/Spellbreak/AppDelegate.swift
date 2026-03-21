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

        // Create shared instances
        appState = AppState()
        soundManager = SoundManager()

        // Create and configure status bar controller immediately
        statusBarController = StatusBarController()
        statusBarController.configure(with: appState)

        // Start timer if it was running before
        if appState.timerWasRunning {
            appState.startTimer()
        }
    }
}