//
//  StatusBarController.swift
//  Spellbreak
//
//  Manages the menu bar status item with both left-click popover and right-click context menu
//

import AppKit
import SwiftUI
import Combine

enum MenuIconStyle: String, CaseIterable {
    case mystical = "mystical"
    case yellow = "yellow"
    case white = "white"
    
    var displayName: String {
        switch self {
        case .mystical: return "Purple"
        case .yellow: return "Yellow"
        case .white: return "White"
        }
    }
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var contextMenu: NSMenu!
    weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var currentIconStyle: MenuIconStyle = .mystical
    private var notificationObserver: Any?
    
    override init() {
        super.init()
        
        // Load saved icon style
        if let savedStyle = UserDefaults.standard.string(forKey: "menuIconStyle"),
           let style = MenuIconStyle(rawValue: savedStyle) {
            currentIconStyle = style
        }
        
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
        let menuView = MenuViewSimple()
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
            let minutes = Int(appState?.timeRemaining ?? 0) / 60
            let seconds = Int(appState?.timeRemaining ?? 0) % 60
            let timerText = String(format: "%d:%02d until break", minutes, seconds)
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
        let timerTitle = appState?.timerRunning == true ? "Pause Timer" : "Start Timer"
        let timerItem = NSMenuItem(title: timerTitle, action: #selector(toggleTimer), keyEquivalent: "")
        timerItem.target = self
        contextMenu.addItem(timerItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        // Icon Style submenu
        let styleMenu = NSMenu()
        for style in MenuIconStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(changeIconStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            item.state = (style == currentIconStyle) ? .on : .off
            styleMenu.addItem(item)
        }
        
        let styleMenuItem = NSMenuItem(title: "Icon Style", action: nil, keyEquivalent: "")
        styleMenuItem.submenu = styleMenu
        contextMenu.addItem(styleMenuItem)
        
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
        if appState?.timerRunning == true {
            appState?.stopTimer()
        } else {
            appState?.startTimer()
        }
        updateIcon()
    }
    
    @objc private func showPreferences() {
        closePopover()
        appState?.showPreferences()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func changeIconStyle(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? MenuIconStyle else { return }
        currentIconStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "menuIconStyle")
        updateIcon()
    }
    
    func updateIcon() {
        guard let button = statusItem.button else { return }
        
        // Create a custom drawn icon like RackOff does
        button.image = createIconImage()
        
        // Update tooltip based on timer state
        if let appState = appState {
            if appState.timerRunning {
                let minutes = Int(appState.timeRemaining) / 60
                let seconds = Int(appState.timeRemaining) % 60
                button.toolTip = String(format: "%d:%02d until break", minutes, seconds)
            } else {
                button.toolTip = "Spellbreak - Click to start"
            }
        }
    }
    
    private func createIconImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Clear background
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw icon based on style - all use same moon design with different colors
        if let context = NSGraphicsContext.current?.cgContext {
            switch currentIconStyle {
            case .mystical:
                drawMoonIcon(context: context, size: size, style: .mystical)
            case .yellow:
                drawMoonIcon(context: context, size: size, style: .yellow)
            case .white:
                drawMoonIcon(context: context, size: size, style: .white)
            }
        }
        
        image.unlockFocus()
        image.isTemplate = false  // Keep colors for all styles
        
        return image
    }
    
    private func drawMoonIcon(context: CGContext, size: NSSize, style: MenuIconStyle) {
        // Set colors based on style
        let moonColor: NSColor
        let starColor: NSColor
        
        switch style {
        case .mystical:
            // Purple/pink gradient colors for mystical theme
            moonColor = NSColor(red: 0.7, green: 0.4, blue: 0.9, alpha: 1.0)
            starColor = NSColor(red: 0.9, green: 0.3, blue: 0.6, alpha: 1.0)
        case .yellow:
            // Golden yellow theme
            moonColor = NSColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
            starColor = NSColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        case .white:
            // Plain white theme
            moonColor = NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            starColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        
        // Draw a crescent moon
        context.setFillColor(moonColor.cgColor)
        
        let moonRadius = size.width * 0.35
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        
        // Main moon circle
        let moonRect = CGRect(x: center.x - moonRadius, y: center.y - moonRadius, 
                              width: moonRadius * 2, height: moonRadius * 2)
        context.fillEllipse(in: moonRect)
        
        // Cut out crescent shape
        context.setBlendMode(.clear)
        let cutRadius = moonRadius * 0.8
        let cutOffset = moonRadius * 0.4
        let cutRect = CGRect(x: center.x - cutRadius + cutOffset, y: center.y - cutRadius,
                             width: cutRadius * 2, height: cutRadius * 2)
        context.fillEllipse(in: cutRect)
        
        // Reset blend mode and draw stars
        context.setBlendMode(.normal)
        context.setFillColor(starColor.cgColor)
        
        // Small stars around moon
        drawStar(context: context, 
                center: CGPoint(x: size.width * 0.8, y: size.height * 0.3),
                size: size.width * 0.12)
        
        drawStar(context: context,
                center: CGPoint(x: size.width * 0.75, y: size.height * 0.7),
                size: size.width * 0.1)
    }
    
    private func drawStar(context: CGContext, center: CGPoint, size: CGFloat) {
        let radius = size / 2
        let innerRadius = radius * 0.4
        let points = 4
        
        let path = CGMutablePath()
        
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points)
            let currentRadius = i % 2 == 0 ? radius : innerRadius
            let x = center.x + cos(angle) * currentRadius
            let y = center.y + sin(angle) * currentRadius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        context.addPath(path)
        context.fillPath()
    }
}