//
//  SpellbreakApp.swift
//  Spellbreak
//
//  Main application entry point managing menu bar presence,
//  overlay presentation, and break scheduling.
//

import SwiftUI
import AppKit
import UserNotifications
import Combine

// MARK: - Transparent Hosting View
/// Fixes white background issue with NSHostingView
final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}

// MARK: - Overlay Window Controller
/// Controller for the full-screen break overlay window
final class OverlayWindowController: NSWindowController {
    init() {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let window = NSWindow(
            contentRect: screen,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .stationary]
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Main App
/// Spellbreak: Break the spell of screen hypnosis
/// Mystical, unskippable breaks that set you free
@main
struct SpellbreakApp: App {
    // MARK: - State
    @StateObject private var appState = AppState()
    
    // MARK: - Initialization
    init() {
        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Body
    var body: some Scene {
        MenuBarExtra {
            MenuViewSimple()
                .environmentObject(appState)
        } label: {
            HeartEyesIcon()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)  // Use window style for timer updates
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Break") {
                    appState.triggerBreak()
                }
                
                Divider()
                
                Button(appState.timerRunning ? "Disable" : "Enable") {
                    if appState.timerRunning {
                        appState.stopTimer()
                    } else {
                        appState.startTimer()
                    }
                }
                
                Button("Settings") {
                    appState.showPreferences()
                }
            }
        }
    }
}

// MARK: - App State
/// Main application state manager handling timers, windows, and statistics
/// This is the central state object that coordinates all app functionality
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var timerRunning = false          // Whether the break timer is active
    @Published var showingOverlay = false        // Whether the break overlay is visible
    @Published var showingPreferences = false    // Whether preferences window is open
    @Published var timeRemaining: TimeInterval = 0  // Seconds until next break
    @Published var todayCompletedBreaks: Int = 0   // Breaks completed today
    @Published var todaySkippedBreaks: Int = 0     // Breaks skipped today
    
    // MARK: - Private Properties
    private var timer: Timer?                    // Main timer for break intervals
    private var statusTimer: Timer?              // Timer for updating UI countdown
    private var lastBreakTime: Date = Date()     // When the last break was triggered
    private var overlayWindowController: OverlayWindowController?    // Break overlay window
    private var preferencesWindowController: NSWindowController?     // Preferences window
    private var overlayCancellable: AnyCancellable?
    private var preferencesCancellable: AnyCancellable?
    private var keyMonitor: Any?                 // Escape key monitor
    
    // MARK: - Persisted Properties
    @AppStorage("breakInterval") private var breakIntervalMinutes: Double = 20.0 {
        didSet {
            // Restart timer if running to apply new interval
            if timerRunning {
                restartTimer()
            }
        }
    }
    @AppStorage("totalCompletedBreaks") var totalCompletedBreaks: Int = 0
    @AppStorage("totalSkippedBreaks") var totalSkippedBreaks: Int = 0
    @AppStorage("lastBreakDate") private var lastBreakDateString: String = ""
    @AppStorage("timerWasRunning") private var timerWasRunning: Bool = false
    @AppStorage("lastBreakTimestamp") private var lastBreakTimestamp: Double = 0
    
    // MARK: - Computed Properties
    private var breakInterval: TimeInterval {
        breakIntervalMinutes * 60
    }
    
    init() {
        setupCombineObservers()
        checkDailyReset()
        restoreTimerState()
        
        // Listen for test break requests from preferences
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowTestBreak"),
            object: nil,
            queue: .main
        ) { _ in
            self.triggerBreak()
        }
    }
    
    func startTimer() {
        stopTimer()
        timerRunning = true
        lastBreakTime = Date()
        timeRemaining = breakInterval  // Initialize with full time
        
        // Save state for persistence
        timerWasRunning = true
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        
        timer = Timer.scheduledTimer(withTimeInterval: breakInterval, repeats: true) { _ in
            self.triggerBreak()
        }
        
        // Update time remaining every second
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let elapsed = Date().timeIntervalSince(self.lastBreakTime)
            self.timeRemaining = max(0, self.breakInterval - elapsed)
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        statusTimer?.invalidate()
        statusTimer = nil
        timerRunning = false
        timeRemaining = 0
        
        // Clear persistence
        timerWasRunning = false
    }
    
    /// Restart the timer with the current break interval
    private func restartTimer() {
        stopTimer()
        startTimer()
    }
    
    func triggerBreak() {
        lastBreakTime = Date()
        showingOverlay = true
        showOverlayWindow()
        showNotification()
        
        // Don't update statistics here - we'll track completion/skip separately
        lastBreakDateString = DateFormatter.dateOnlyFormatter.string(from: Date())
    }
    
    func markBreakCompleted() {
        totalCompletedBreaks += 1
        todayCompletedBreaks += 1
        checkDailyReset()
    }
    
    func markBreakSkipped() {
        totalSkippedBreaks += 1
        todaySkippedBreaks += 1
        checkDailyReset()
    }
    
    private func setupCombineObservers() {
        // Watch for overlay state changes using Combine (no polling!)
        overlayCancellable = $showingOverlay
            .removeDuplicates()
            .sink { [weak self] showing in
                if !showing {
                    self?.overlayWindowController?.close()
                    self?.overlayWindowController = nil
                }
            }
        
        preferencesCancellable = $showingPreferences
            .removeDuplicates()
            .sink { [weak self] showing in
                if !showing {
                    self?.preferencesWindowController?.close()
                    self?.preferencesWindowController = nil
                }
            }
    }
    
    func showPreferences() {
        showingPreferences = true
        
        if preferencesWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Spellbreak Preferences"
            window.center()
            window.contentView = NSHostingView(rootView: PreferencesView())
            window.isMovableByWindowBackground = false  // Fixed: Don't allow dragging by background
            window.titlebarAppearsTransparent = true
            window.styleMask.remove(.resizable)  // Prevent resizing to lock the size
            
            preferencesWindowController = NSWindowController(window: window)
        }
        
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showOverlayWindow() {
        overlayWindowController = OverlayWindowController()
        guard let window = overlayWindowController?.window else { return }
        
        // Use the good SwiftUI overlay with animated effects
        let overlayView = OverlayWindow()
            .environmentObject(self)
        
        window.contentView = NSHostingView(rootView: overlayView)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.isReleasedWhenClosed = false
        
        // Add escape key handler
        if let existingMonitor = keyMonitor {
            NSEvent.removeMonitor(existingMonitor)
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                window.close()
                self?.showingOverlay = false
                return nil
            }
            return event
        }
        
        // Bring it all the way front
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func showNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break"
        content.body = "Look away from your screen for 20 seconds"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func checkDailyReset() {
        let today = DateFormatter.dateOnlyFormatter.string(from: Date())
        if lastBreakDateString != today {
            todayCompletedBreaks = 0
            todaySkippedBreaks = 0
        }
    }
    
    /// Restore timer state after app restart
    private func restoreTimerState() {
        guard timerWasRunning && lastBreakTimestamp > 0 else { return }
        
        let lastBreak = Date(timeIntervalSince1970: lastBreakTimestamp)
        let elapsed = Date().timeIntervalSince(lastBreak)
        
        // If we're still within the break interval, restore the timer
        if elapsed < breakInterval {
            lastBreakTime = lastBreak
            timerRunning = true
            
            // Calculate remaining time until next break
            let remainingTime = breakInterval - elapsed
            
            // Set up timer for the remaining time
            timer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { _ in
                self.triggerBreak()
                // After this break, continue with regular intervals
                self.timer = Timer.scheduledTimer(withTimeInterval: self.breakInterval, repeats: true) { _ in
                    self.triggerBreak()
                }
            }
            
            // Update time remaining every second
            statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                let elapsed = Date().timeIntervalSince(self.lastBreakTime)
                self.timeRemaining = max(0, self.breakInterval - elapsed)
            }
        } else {
            // Timer expired while app was closed, trigger break now if appropriate
            timerWasRunning = false
            if elapsed < breakInterval * 2 {
                // Only trigger if we're not too far past the scheduled time
                triggerBreak()
            }
        }
    }
}

extension DateFormatter {
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}