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
    case plain = "plain"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .mystical: return "🌙 Mystical"
        case .plain: return "○ Plain"
        case .minimal: return "• Minimal"
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
        popover.animates = true
        
        // Setup context menu for right-click
        setupContextMenu()
    }
    
    func configure(with appState: AppState) {
        self.appState = appState
        
        // Configure popover content
        let menuView = MenuViewSimple()
            .environmentObject(appState)
        
        popover.contentViewController = NSHostingController(rootView: menuView)
        popover.contentSize = NSSize(width: 220, height: NSSize.zero.height)
        
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
            // Show context menu on right-click
            showContextMenu()
        } else {
            // Toggle popover on left-click
            togglePopover()
        }
    }
    
    private func setupContextMenu() {
        contextMenu = NSMenu()
        contextMenu.autoenablesItems = false
        
        // Break Now
        let breakItem = NSMenuItem(title: "Break Now", action: #selector(triggerBreak), keyEquivalent: "")
        breakItem.target = self
        contextMenu.addItem(breakItem)
        
        contextMenu.addItem(NSMenuItem.separator())
        
        // Timer toggle
        let timerItem = NSMenuItem(title: "Start Timer", action: #selector(toggleTimer), keyEquivalent: "")
        timerItem.target = self
        timerItem.tag = 100 // Tag to identify for updating
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
        // Update timer menu item based on current state
        if let timerItem = contextMenu.item(withTag: 100) {
            timerItem.title = appState?.timerRunning == true ? "Pause Timer" : "Start Timer"
        }
        
        // Update icon style checkmarks
        if let styleMenuItem = contextMenu.item(withTitle: "Icon Style"),
           let styleSubmenu = styleMenuItem.submenu {
            for item in styleSubmenu.items {
                if let itemStyle = item.representedObject as? MenuIconStyle {
                    item.state = (itemStyle == currentIconStyle) ? .on : .off
                }
            }
        }
        
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
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Make popover window key and bring to front
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
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
        
        // Draw icon based on style
        if let context = NSGraphicsContext.current?.cgContext {
            switch currentIconStyle {
            case .mystical:
                drawMysticalIcon(context: context, size: size)
            case .plain:
                drawPlainIcon(context: context, size: size)
            case .minimal:
                drawMinimalIcon(context: context, size: size)
            }
        }
        
        image.unlockFocus()
        image.isTemplate = (currentIconStyle != .mystical)  // Template for plain/minimal
        
        return image
    }
    
    private func drawMysticalIcon(context: CGContext, size: NSSize) {
        // Purple/pink gradient colors for mystical theme
        let color1 = NSColor(red: 0.7, green: 0.4, blue: 0.9, alpha: 1.0)
        let color2 = NSColor(red: 0.9, green: 0.3, blue: 0.6, alpha: 1.0)
        
        // Draw a crescent moon
        context.setFillColor(color1.cgColor)
        
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
        context.setFillColor(color2.cgColor)
        
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
    
    private func drawPlainIcon(context: CGContext, size: NSSize) {
        // Simple circle icon - will use system color when template
        let color = NSColor.labelColor
        context.setFillColor(color.cgColor)
        
        let radius = size.width * 0.3
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, 
                         width: radius * 2, height: radius * 2)
        
        context.fillEllipse(in: rect)
    }
    
    private func drawMinimalIcon(context: CGContext, size: NSSize) {
        // Minimal dot icon - will use system color when template  
        let color = NSColor.labelColor
        context.setFillColor(color.cgColor)
        
        let radius = size.width * 0.15
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                         width: radius * 2, height: radius * 2)
        
        context.fillEllipse(in: rect)
    }
}