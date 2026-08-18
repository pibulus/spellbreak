//
//  StatusBarController.swift
//  Spellbreak
//
//  Manages the menu bar status item with both left-click popover and right-click context menu
//

import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var contextMenu: NSMenu!
    weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var notificationObserver: Any?

    override init() {
        super.init()

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            // Set icon
            updateIcon()
            
            // Handle both left and right clicks
            statusButton.action = #selector(handleClick)
            statusButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusButton.target = self
        }
        
        // Setup popover for left-click menu
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true  // Smooth animation
        
        // Setup context menu for right-click
        setupContextMenu()
    }
    
    deinit {
        // Clean up notification observer
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // Cancel all Combine subscriptions
        cancellables.forEach { $0.cancel() }
    }
    
    func configure(with appState: AppState) {
        self.appState = appState
        
        // Configure popover content
        let menuView = MenuViewSimple(onRequestClose: { [weak self] in
            self?.closePopover()
        })
            .environmentObject(appState)
        
        popover.contentViewController = NSHostingController(rootView: menuView)
        popover.contentSize = NSSize(width: 200, height: NSSize.zero.height)
        
        // Observe timer changes to update tooltip
        appState.$timerRunning
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
        
        appState.$timeRemaining
            .sink { [weak self] _ in
                self?.updateIcon()
            }
            .store(in: &cancellables)
        
        // Listen for fancy menu preference changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Close popover if switching to plain menu
            let fancyMenu = UserDefaults.standard.object(forKey: "fancyMenu") as? Bool ?? true
            if !fancyMenu && self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }
    }
    
    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Close popover first if open
            if popover.isShown {
                popover.performClose(nil)
            }
            // Show context menu on right-click
            showContextMenu()
        } else {
            // Check if fancy menu is enabled (defaults to true)
            let fancyMenu = UserDefaults.standard.object(forKey: "fancyMenu") as? Bool ?? true
            
            if fancyMenu {
                // Show fancy popover for left-click
                togglePopover()
            } else {
                // Show same context menu for left-click when fancy is off
                if popover.isShown {
                    popover.performClose(nil)
                }
                showContextMenu()
            }
        }
    }
    
    private func setupContextMenu() {
        contextMenu = NSMenu()
        contextMenu.autoenablesItems = false
        
        // Timer display (if running)
        if appState?.timerRunning == true {
            let timerText = "\((appState?.timeRemaining ?? 0).mmss) until break"
            let timerItem = NSMenuItem(title: timerText, action: nil, keyEquivalent: "")
            timerItem.isEnabled = false
            contextMenu.addItem(timerItem)
            contextMenu.addItem(NSMenuItem.separator())
        }
        
        // Break Now
        let breakItem = NSMenuItem(title: "Break Now", action: #selector(triggerBreak), keyEquivalent: "")
        breakItem.target = self
        contextMenu.addItem(breakItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        // Timer toggle
        let timerTitle: String
        if appState?.timerRunning == true {
            timerTitle = "Pause Timer"
        } else {
            timerTitle = appState?.timerPaused == true ? "Resume Timer" : "Start Timer"
        }
        let timerItem = NSMenuItem(title: timerTitle, action: #selector(toggleTimer), keyEquivalent: "")
        timerItem.target = self
        contextMenu.addItem(timerItem)
        
        contextMenu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: "")
        prefsItem.target = self
        contextMenu.addItem(prefsItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Spellbreak", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        contextMenu.addItem(quitItem)
    }
    
    private func showContextMenu() {
        // Rebuild context menu to get fresh timer values
        setupContextMenu()
        
        // Show the context menu
        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)
        
        // Clean up after showing
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Calculate the rect to center the popover arrow on the button
            let buttonWidth = button.bounds.width
            // Create a 1px wide rect in the center of the button
            let centerRect = NSRect(x: buttonWidth / 2, y: 0, width: 1, height: button.bounds.height)
            
            // Show popover centered
            popover.show(relativeTo: centerRect, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
    
    @objc private func triggerBreak() {
        closePopover()
        appState?.triggerBreak()
    }
    
    @objc private func toggleTimer() {
        appState?.toggleTimer()
        updateIcon()
    }
    
    @objc private func showPreferences() {
        closePopover()
        appState?.showPreferences()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateIcon() {
        guard let button = statusItem.button else { return }
        let timerRunning = appState?.timerRunning == true

        if button.image == nil {
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            let image = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Spellbreak")?
                .withSymbolConfiguration(config)
            image?.isTemplate = true  // System tints for light/dark menu bars
            button.image = image
        }

        button.appearsDisabled = !timerRunning  // Native dim when paused

        // Update tooltip based on timer state
        let statusText = iconStatusText
        button.toolTip = statusText
        button.setAccessibilityLabel("Spellbreak")
        button.setAccessibilityValue(statusText)
    }
    
    private var iconStatusText: String {
        guard let appState = appState else { return "Spellbreak" }

        if appState.timerRunning {
            return "Spellbreak: \(appState.timeRemaining.mmss) until break"
        } else if appState.timerPaused {
            return "Spellbreak: paused at \(appState.timeRemaining.mmss)"
        } else {
            return "Spellbreak: timer off"
        }
    }

}
