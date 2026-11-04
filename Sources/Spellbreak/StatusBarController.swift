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
    private var lastRenderedTooltip: String = ""
    private var lastRenderedDisabled: Bool?

    override init() {
        super.init()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let statusButton = statusItem.button {
            updateIcon(force: true)

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

        setupContextMenu()
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }

    func configure(with appState: AppState) {
        self.appState = appState

        let menuView = MenuViewSimple(onRequestClose: { [weak self] in
            self?.closePopover()
        })
            .environmentObject(appState)

        popover.contentViewController = NSHostingController(rootView: menuView)
        popover.contentSize = NSSize(width: 208, height: NSSize.zero.height)

        appState.$timerRunning
            .Merge(with: appState.$timerPaused)
            .sink { [weak self] _ in
                self?.updateIcon(force: true)
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
            if popover.isShown {
                popover.performClose(nil)
            }
            showContextMenu()
        } else {
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

        // Settings…
        let prefsItem = NSMenuItem(title: "Settings…", action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.keyEquivalentModifierMask = [.command]
        prefsItem.target = self
        contextMenu.addItem(prefsItem)

        contextMenu.addItem(NSMenuItem.separator())

        // Quit Spellbreak
        let quitItem = NSMenuItem(title: "Quit Spellbreak", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        contextMenu.addItem(quitItem)
    }

    private func showContextMenu() {
        setupContextMenu()

        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)

        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            let buttonWidth = button.bounds.width
            let centerRect = NSRect(x: buttonWidth / 2, y: 0, width: 1, height: button.bounds.height)

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
        updateIcon(force: true)
    }

    @objc private func showPreferences() {
        closePopover()
        appState?.showPreferences()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func updateIcon(force: Bool = false) {
        guard let button = statusItem.button else { return }
        let timerRunning = appState?.timerRunning == true

        if button.image == nil {
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            let image = NSImage(systemSymbolName: "moon.stars", accessibilityDescription: "Spellbreak")?
                .withSymbolConfiguration(config)
            image?.isTemplate = true
            button.image = image
        }

        let nextDisabled = !timerRunning
        let nextTooltip = iconTooltipText
        guard force || nextDisabled != lastRenderedDisabled || nextTooltip != lastRenderedTooltip else {
            return
        }

        lastRenderedDisabled = nextDisabled
        lastRenderedTooltip = nextTooltip
        button.appearsDisabled = nextDisabled
        button.toolTip = nextTooltip
        button.setAccessibilityLabel("Spellbreak")
        button.setAccessibilityValue(iconAccessibilityValue)
    }

    private var iconTooltipText: String {
        guard let appState = appState else { return "Spellbreak" }

        if appState.timerRunning {
            return "Spellbreak: \(appState.timeRemaining.mmss) until break"
        } else if appState.timerPaused {
            return "Spellbreak: paused at \(appState.timeRemaining.mmss)"
        } else {
            return "Spellbreak: timer off"
        }
    }

    private var iconAccessibilityValue: String {
        guard let appState = appState else { return "Timer off" }

        if appState.timerRunning {
            return "\(appState.timeRemaining.spokenDuration) until break"
        } else if appState.timerPaused {
            return "Paused at \(appState.timeRemaining.spokenDuration)"
        } else {
            return "Timer off"
        }
    }
}

private extension Publisher where Failure == Never {
    func Merge<P: Publisher>(with other: P) -> Publishers.Merge<Self, P> where P.Output == Output, P.Failure == Never {
        Publishers.Merge(self, other)
    }
}
