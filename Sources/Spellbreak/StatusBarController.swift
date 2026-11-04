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
        
        // Setup popover for left-click menu — pin darkAqua so macOS Light Mode
        // never turns the popover chrome white behind warm cream text
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        
        // Setup context menu for right-click
        setupContextMenu()
    }
    
    deinit {
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
        popover.contentSize = NSSize(width: 208, height: NSSize.zero.height)
        
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
            // Left-click always opens the signature dark popover
            togglePopover()
        }
    }
    
    private func setupContextMenu() {
        contextMenu = NSMenu()
        contextMenu.autoenablesItems = false
        
        if appState?.timerRunning == true {
            let item = NSMenuItem(title: "\((appState?.timeRemaining ?? 0).mmss) until break", action: nil, keyEquivalent: "")
            item.isEnabled = false
            contextMenu.addItem(item)
            contextMenu.addItem(NSMenuItem.separator())
        }
        
        // Break Now
        let breakItem = NSMenuItem(title: "Break Now", action: #selector(triggerBreak), keyEquivalent: "")
        breakItem.target = self
        contextMenu.addItem(breakItem)
        
        // Timer toggle
        let timerTitle: String
        if appState?.timerRunning == true {
            timerTitle = "Pause"
        } else {
            timerTitle = appState?.timerPaused == true ? "Resume" : "Start"
        }
        let timerItem = NSMenuItem(title: timerTitle, action: #selector(toggleTimer), keyEquivalent: "")
        timerItem.target = self
        contextMenu.addItem(timerItem)
        
        contextMenu.addItem(NSMenuItem.separator())

        // Settings
        let prefsItem = NSMenuItem(title: "Settings", action: #selector(showPreferences), keyEquivalent: "")
        prefsItem.target = self
        contextMenu.addItem(prefsItem)
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "")
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
