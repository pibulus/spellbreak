//
//  AppDelegate.swift
//  Spellbreak
//
//  App delegate to manage the status bar controller and standard menu shortcuts.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController!
    var appState: AppState!
    var soundManager: SoundManager!
    var store: Store!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon since we're a menu bar app
        NSApp.setActivationPolicy(.accessory)

        soundManager = SoundManager()
        store = Store()
        appState = AppState(soundManager: soundManager, store: store)

        // Create and configure status bar controller immediately
        statusBarController = StatusBarController()
        statusBarController.configure(with: appState)

        // Install standard macOS main menu so Command-, opens Settings, Command-W
        // closes it, and Command-Q quits cleanly without spawning SwiftUI's empty Settings stub.
        installMainMenu()
        DispatchQueue.main.async { [weak self] in
            self?.installMainMenu()
        }

        // First launch: we're a faceless menu bar app, so show Preferences
        // once so new users see *something* (and can hit Start / Test Break)
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            defaults.set(true, forKey: "hasLaunchedBefore")
            appState.showPreferences()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Keep Command-, pointed at our PreferencesWindow even if SwiftUI refreshes menu items.
        rewireSettingsMenuItems()
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        // Application menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Spellbreak")

        let aboutItem = NSMenuItem(
            title: "About Spellbreak",
            action: #selector(openAboutFromMenu),
            keyEquivalent: ""
        )
        aboutItem.target = self
        appMenu.addItem(aboutItem)
        appMenu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = [.command]
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Spellbreak",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Edit menu (enables standard responder-chain Cut / Copy / Paste / Select All in sheets & dialogs)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window menu (enables standard Command-W to close Settings)
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        let closeItem = NSMenuItem(
            title: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        closeItem.keyEquivalentModifierMask = [.command]
        windowMenu.addItem(closeItem)
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func rewireSettingsMenuItems() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }
        for item in appMenu.items where item.keyEquivalent == "," {
            item.title = "Settings…"
            item.target = self
            item.action = #selector(openSettingsFromMenu)
        }
    }

    @objc private func openSettingsFromMenu() {
        appState?.showPreferences()
    }

    @objc private func openAboutFromMenu() {
        appState?.showPreferences(selectingTab: 2)
    }
}
