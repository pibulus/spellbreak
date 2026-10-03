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
/// Controller for one display's full-screen break overlay. One per display: a
/// single window stretched across them all only ever drew on one, because with
/// "Displays have separate Spaces" on (macOS's default) windows can't span displays.
final class OverlayWindowController: NSWindowController {
    init(frame: NSRect?) {
        let window = NSWindow(
            contentRect: frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800),
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

// MARK: - Preferences Window Controller
/// Keeps AppState in sync with normal macOS window close behavior.
final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void

    init(window: NSWindow, onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init(window: window)
        window.delegate = self
        window.isReleasedWhenClosed = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// MARK: - Main App
/// Spellbreak: Break the spell of screen hypnosis
/// Mystical, unskippable breaks that set you free
@main
struct SpellbreakApp: App {
    // MARK: - State
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Body
    var body: some Scene {
        // Empty scene - we're using NSStatusItem directly now
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App State
/// Main application state manager handling timers, windows, and statistics
/// This is the central state object that coordinates all app functionality
class AppState: ObservableObject {
    private enum NotificationName {
        static let showTestBreak = NSNotification.Name("ShowTestBreak")
        static let escapePressed = NSNotification.Name("EscapePressed")
    }

    // MARK: - Published Properties
    @Published var timerRunning = false          // Whether the break timer is active
    @Published var showingOverlay = false        // Whether the break overlay is visible
    @Published var showingPreferences = false    // Whether preferences window is open
    @Published var timeRemaining: TimeInterval = 0  // Seconds until next break
    @Published var timerPaused = false            // Stopped, but holding its place
    // Today's counts survive a relaunch; checkDailyReset() zeroes them at midnight
    @Published var todayCompletedBreaks: Int = UserDefaults.standard.integer(forKey: "todayCompletedBreaks") {
        didSet { UserDefaults.standard.set(todayCompletedBreaks, forKey: "todayCompletedBreaks") }
    }
    @Published var todaySkippedBreaks: Int = UserDefaults.standard.integer(forKey: "todaySkippedBreaks") {
        didSet { UserDefaults.standard.set(todaySkippedBreaks, forKey: "todaySkippedBreaks") }
    }

    /// "3 breaks today · 1 skipped" — the small honest scoreboard, nil before the first
    var todaySummary: String? {
        let taken = todayCompletedBreaks
        let skipped = todaySkippedBreaks
        guard taken + skipped > 0 else { return nil }
        let breaks = "\(taken) \(taken == 1 ? "break" : "breaks") today"
        return skipped > 0 ? "\(breaks) · \(skipped) skipped" : breaks
    }
    
    // MARK: - Private Properties
    weak var soundManager: SoundManager?         // Injected by AppDelegate at launch (NSApp.delegate is SwiftUI's wrapper during launch, so we can't reach it that way)
    weak var store: Store?                       // Injected the same way; the App Store unlock
    private var timer: Timer?                    // Main timer for break intervals
    private var statusTimer: Timer?              // Timer for updating UI countdown
    private var lastBreakTime: Date = Date()     // When the last break was triggered
    private var overlayWindowController: OverlayWindowController?    // Break overlay window (the pointer's display)
    private var mirrorWindowControllers: [OverlayWindowController] = []  // Every other display: the same aurora, quiet
    private var preferencesWindowController: PreferencesWindowController?     // Preferences window
    private var overlayCancellable: AnyCancellable?
    private var overlayFailsafe: DispatchWorkItem?
    private var countdownWindowController: BreakCountdownWindowController?
    private var preferencesCancellable: AnyCancellable?
    private var escapeKeyMonitor: Any?          // Event monitor for escape key
    private var testBreakObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var unlockObserver: NSObjectProtocol?
    private var didShowBreakWarning = false
    private var currentBreakCountsTowardStats = true
    private let breakWarningLeadTime: TimeInterval = 15
    
    // MARK: - Break Statistics (for message generation)
    private var sessionBreakCount: Int = 0       // Breaks taken this session
    private var sessionSkippedCount: Int = 0     // Breaks skipped this session
    private var lastBreakCompletedTime: Date?    // When last break was completed (not skipped)
    
    // MARK: - Persisted Properties
    @AppStorage("breakIntervalMin") private var breakIntervalMinutes: Double = 20.0 {
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
    @AppStorage("timerWasRunning") var timerWasRunning: Bool = false
    @AppStorage("lastBreakTimestamp") private var lastBreakTimestamp: Double = 0
    @AppStorage("breakWarningEnabled") private var breakWarningEnabled: Bool = true
    @AppStorage("deferDuringFullscreen") private var deferDuringFullscreen: Bool = true
    /// Seconds banked by pauseTimer(), spent by resumeTimer().
    private var pausedRemaining: TimeInterval = 0
    /// Wall clock and awake-time at the last tick. The gap between them is sleep.
    private var lastTickWallClock = Date()
    private var lastTickUptime = ProcessInfo.processInfo.systemUptime
    /// Keyboard and mouse untouched for an away-length stretch — see restartIntervalIfUserCameBack()
    private var userIsAway = false
    /// When the current wait-for-a-pause-in-typing began, if one's running
    private var typingHoldStartedAt: Date?

    // MARK: - Computed Properties
    private var breakInterval: TimeInterval {
        guard breakIntervalMinutes.isFinite else { return 20 * 60 }
        return max(60, breakIntervalMinutes * 60)
    }
    
    init() {
        setupCombineObservers()
        checkDailyReset()
        restoreTimerState()

        // Debug hook: SPELLBREAK_FIRE_NOW=1 fires a test break 3s after launch,
        // bypassing prefs/timer state — the only reliable repro lever for
        // headless overlay testing (prefs tricks fight cfprefsd + the sandbox)
        if ProcessInfo.processInfo.environment["SPELLBREAK_FIRE_NOW"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.triggerBreak(countsTowardStats: false, resetsTimerAnchor: false)
            }
        }
        
        // Listen for test break requests from preferences
        testBreakObserver = NotificationCenter.default.addObserver(
            forName: NotificationName.showTestBreak,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerBreak(
                resetTimerSchedule: false,
                countsTowardStats: false,
                resetsTimerAnchor: false
            )
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWake()
        }

        // Starting the free week (or unlocking) is a decision to have breaks — so start them
        unlockObserver = NotificationCenter.default.addObserver(
            forName: Store.didUnlockScheduledBreaks,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, !self.timerRunning else { return }
            self.resumeTimer()
        }
    }
    
    deinit {
        // Clean up timers
        timer?.invalidate()
        statusTimer?.invalidate()
        overlayFailsafe?.cancel()
        countdownWindowController?.close()

        if let observer = testBreakObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }

        if let observer = unlockObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Remove escape key monitor if present
        if let monitor = escapeKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // Cancel Combine subscriptions
        overlayCancellable?.cancel()
        preferencesCancellable?.cancel()
    }
    
    func startTimer() {
        stopTimer()
        timerRunning = true
        lastBreakTime = Date()
        timeRemaining = breakInterval  // Initialize with full time
        didShowBreakWarning = false
        
        // Save state for persistence
        timerWasRunning = true
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        requestNotificationAuthorizationIfNeeded()

        // Ticks stop while the timer is off; don't mistake that gap for sleep or
        // absence, or a resume would "restart" the interval and lose its place
        lastTickWallClock = Date()
        lastTickUptime = ProcessInfo.processInfo.systemUptime
        userIsAway = false
        
        scheduleRepeatingBreakTimer()
        
        startStatusTimer()
        updateTimeRemainingAndWarning()
    }
    
    func stopTimer() {
        timerPaused = false
        pausedRemaining = 0
        timer?.invalidate()
        timer = nil
        statusTimer?.invalidate()
        statusTimer = nil
        timerRunning = false
        timeRemaining = 0
        didShowBreakWarning = false
        hideCountdownPill()

        // Clear persistence
        timerWasRunning = false
    }
    
    /// Hold an AUTOMATIC break while the user is plainly mid-something — a fullscreen
    /// game, a film, a presentation, a call, a sentence. The anchor is left alone and
    /// this is re-asked every second, so the break lands the moment they come back
    /// out rather than being skipped. Being away from the Mac holds it too, but that
    /// one ends with the interval starting over (restartIntervalIfUserCameBack).
    /// "Break Now" from the menu ignores all of this: an explicitly requested break is
    /// never second-guessed.
    private func shouldHoldBreak() -> Bool {
        if userIsAway { return true }  // an empty chair needs no break; the interval restarts on return
        guard deferDuringFullscreen else { return false }
        return ScreenBusy.isBusy() || isMidSentence()
    }

    /// Typing when a break comes due? Let the sentence land first: wait for a pause
    /// in the keys (two quiet seconds), but no more than 30 seconds, so a non-stop
    /// typist still gets the break. The same never-stuck-on-busy rule as the rest.
    private func isMidSentence() -> Bool {
        guard ScreenBusy.secondsSinceLastKeystroke() < 2 else {
            typingHoldStartedAt = nil
            return false
        }
        let started = typingHoldStartedAt ?? Date()
        typingHoldStartedAt = started
        return Date().timeIntervalSince(started) < 30
    }

    /// A few minutes (or a break's length, if longer) without touching the keyboard
    /// or mouse is a break by any measure, same as a closed lid. While you're away a
    /// due break waits — no point showing it to an empty chair — and once you're
    /// back the interval starts over, instead of landing a break as you sit down.
    /// Whichever tick sees you return first restarts it. True when it restarted.
    ///
    /// Still hands with a video or call holding the display awake isn't away: that's
    /// someone watching, the exact trance a break is for.
    @discardableResult
    private func restartIntervalIfUserCameBack() -> Bool {
        let breakSeconds = UserDefaults.standard.object(forKey: "breakDurationSec") as? Double ?? 20
        if ScreenBusy.secondsSinceLastInput() >= max(3 * 60, breakSeconds),
           !ScreenBusy.displayIsHeldAwake() {
            userIsAway = true
            return false
        }
        guard userIsAway else { return false }
        userIsAway = false

        guard timerRunning else { return false }
        lastBreakTime = Date()
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        didShowBreakWarning = false
        scheduleRepeatingBreakTimer()
        return true
    }

    /// Freeze the countdown where it stands. Everything downstream derives the
    /// remaining time from `lastBreakTime`, so pausing is really just remembering
    /// how much was left — and resuming is putting the anchor back that far in the
    /// past, so the count picks up mid-stride instead of starting the interval over.
    func pauseTimer() {
        guard timerRunning else { return }

        let remaining = max(0, breakInterval - Date().timeIntervalSince(lastBreakTime))
        stopTimer()
        pausedRemaining = remaining
        timerPaused = true
        timeRemaining = remaining  // keep the frozen number on screen
    }

    func resumeTimer() {
        // A pause with nothing banked (or a resume out of nowhere) starts a fresh interval.
        let remaining = pausedRemaining > 0 ? pausedRemaining : breakInterval

        timerPaused = false
        pausedRemaining = 0
        startTimer()

        lastBreakTime = Date().addingTimeInterval(remaining - breakInterval)
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        updateTimeRemainingAndWarning()
    }

    /// One control, not two. "Pause" that silently means "reset to twenty minutes"
    /// is the kind of small lie that makes an app feel untrustworthy.
    func toggleTimer() {
        if timerRunning {
            pauseTimer()
        } else if scheduledBreaksAllowed {
            resumeTimer()
        } else {
            showPreferences()  // the free week / unlock lives at the bottom of Settings
        }
    }

    /// Test Break and Break Now always work; scheduled breaks are what the App Store
    /// unlock pays for. No store means the website build: never locked.
    private var scheduledBreaksAllowed: Bool {
        store?.allowsScheduledBreaks ?? true
    }

    /// The free week ran out: the break that was due becomes the unlock prompt,
    /// once, instead of a break. The timer stops so it doesn't ask again.
    private func lockScheduledBreaks() {
        stopTimer()
        showPreferences()
    }

    /// Restart the timer with the current break interval
    private func restartTimer() {
        stopTimer()
        startTimer()
    }

    private func scheduleRepeatingBreakTimer() {
        timer?.invalidate()
        timer = Timer.scheduledCommonTimer(withTimeInterval: max(0.1, breakInterval), repeats: true) { [weak self] _ in
            self?.checkAndTriggerBreak()
        }
    }

    func checkAndTriggerBreak() {
        guard timerRunning else { return }
        guard !restartIntervalIfMacSlept() else { return }
        guard !restartIntervalIfUserCameBack() else { return }
        guard !shouldHoldBreak() else { return }
        guard scheduledBreaksAllowed else {
            lockScheduledBreaks()
            return
        }
        triggerBreak(resetTimerSchedule: false)
    }

    /// Time with the lid shut is time away from the screen — a break by any measure.
    /// Wall-clock time runs on through sleep and system uptime doesn't, so the gap
    /// between them is how long the Mac slept. Long enough, and the interval starts
    /// over: before this, every wake past the interval opened straight onto a break
    /// (the overdue timer and the status tick both fire the moment the Mac wakes).
    /// Whichever of them runs first after a wake absorbs it. True when it restarted.
    @discardableResult
    private func restartIntervalIfMacSlept() -> Bool {
        let now = Date()
        let uptime = ProcessInfo.processInfo.systemUptime
        let slept = now.timeIntervalSince(lastTickWallClock) - (uptime - lastTickUptime)
        lastTickWallClock = now
        lastTickUptime = uptime

        let breakSeconds = UserDefaults.standard.object(forKey: "breakDurationSec") as? Double ?? 20
        guard timerRunning, slept >= max(60, breakSeconds) else { return false }

        lastBreakTime = now
        lastBreakTimestamp = now.timeIntervalSince1970
        didShowBreakWarning = false
        scheduleRepeatingBreakTimer()
        return true
    }

    func triggerBreak(
        resetTimerSchedule: Bool = true,
        countsTowardStats: Bool = true,
        resetsTimerAnchor: Bool = true
    ) {
        guard !showingOverlay else { return }

        currentBreakCountsTowardStats = countsTowardStats
        typingHoldStartedAt = nil  // the next due break gets its own 30 seconds of patience

        if resetsTimerAnchor {
            lastBreakTime = Date()
            lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
            didShowBreakWarning = false
        }

        if timerRunning && resetTimerSchedule {
            scheduleRepeatingBreakTimer()
        }

        hideCountdownPill()
        showingOverlay = true
        showOverlayWindow()
        armOverlayFailsafe()
    }

    /// Last-resort unwedge: if the overlay never resolves (e.g. its window never
    /// reached the screen), reset showingOverlay so future breaks can still fire
    private func armOverlayFailsafe() {
        overlayFailsafe?.cancel()
        let failsafe = DispatchWorkItem { [weak self] in
            guard let self = self, self.showingOverlay else { return }
            self.showingOverlay = false
        }
        overlayFailsafe = failsafe
        let breakSeconds = UserDefaults.standard.object(forKey: "breakDurationSec") as? Double ?? 20
        DispatchQueue.main.asyncAfter(deadline: .now() + breakSeconds + 30, execute: failsafe)
    }
    
    func markBreakCompleted() {
        guard currentBreakCountsTowardStats else {
            currentBreakCountsTowardStats = true
            return
        }

        checkDailyReset()
        totalCompletedBreaks += 1
        todayCompletedBreaks += 1
        sessionBreakCount += 1
        lastBreakCompletedTime = Date()
    }
    
    func markBreakSkipped() {
        guard currentBreakCountsTowardStats else {
            currentBreakCountsTowardStats = true
            return
        }

        checkDailyReset()
        totalSkippedBreaks += 1
        todaySkippedBreaks += 1
        sessionSkippedCount += 1
    }
    
    // Get break context for message generation
    func getBreakContext() -> (breakCount: Int, skippedCount: Int, lastBreakInterval: TimeInterval?) {
        let interval: TimeInterval? = lastBreakCompletedTime.map { Date().timeIntervalSince($0) }
        return (sessionBreakCount, sessionSkippedCount, interval)
    }
    
    private func setupCombineObservers() {
        // Watch for overlay state changes using Combine (no polling!)
        overlayCancellable = $showingOverlay
            .removeDuplicates()
            .sink { [weak self] showing in
                if !showing {
                    self?.overlayFailsafe?.cancel()
                    self?.overlayFailsafe = nil
                    // Remove escape key monitor when closing overlay
                    if let monitor = self?.escapeKeyMonitor {
                        NSEvent.removeMonitor(monitor)
                        self?.escapeKeyMonitor = nil
                    }
                    self?.overlayWindowController?.close()
                    self?.overlayWindowController = nil
                    // Already faded out alongside the break (OverlayMirror.fadeOut)
                    self?.mirrorWindowControllers.forEach { $0.close() }
                    self?.mirrorWindowControllers = []
                }
            }
        
        preferencesCancellable = $showingPreferences
            .removeDuplicates()
            .sink { [weak self] showing in
                if !showing {
                    guard let controller = self?.preferencesWindowController else { return }
                    self?.preferencesWindowController = nil
                    controller.close()
                }
            }
    }
    
    func showPreferences() {
        showingPreferences = true
        
        if preferencesWindowController == nil {
            guard let soundManager, let store else { return }
            let preferences = PreferencesView()
                .environmentObject(soundManager)
                .environmentObject(store)

            // Settings is a fixed ~810pt tall and can't be resized. On a smaller
            // display — a 13" Air at default scaling with the Dock showing, or any Mac
            // set to "Larger Text" — that's taller than the screen, and the bottom of
            // it (Test Break included) lands under the Dock. Fit it, and scroll.
            let styleMask: NSWindow.StyleMask = [.titled, .closable]
            let titleBarHeight = NSWindow.frameRect(forContentRect: .zero, styleMask: styleMask).height
            let fittingHeight = NSHostingView(rootView: preferences).fittingSize.height
            let availableHeight = (NSScreen.main?.visibleFrame.height ?? .greatestFiniteMagnitude) - titleBarHeight
            let contentHeight = min(fittingHeight, availableHeight)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: contentHeight),
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = "Spellbreak Settings"
            if fittingHeight > availableHeight {
                window.contentView = NSHostingView(rootView: ScrollView { preferences }
                    .frame(width: 560, height: contentHeight)
                )
            } else {
                window.contentView = NSHostingView(rootView: preferences)
            }
            window.center()
            window.isMovableByWindowBackground = false  // Fixed: Don't allow dragging by background
            window.titlebarAppearsTransparent = true
            window.styleMask.remove(.resizable)  // Prevent resizing to lock the size
            
            preferencesWindowController = PreferencesWindowController(window: window) { [weak self] in
                self?.handlePreferencesWindowClosed()
            }
        }
        
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handlePreferencesWindowClosed() {
        preferencesWindowController = nil
        if showingPreferences {
            showingPreferences = false
        }
    }
    
    private func showOverlayWindow() {
        // The break itself — line, ring, sound — goes on the display with the
        // pointer, where the hand already is. Every other display gets the same
        // aurora, quiet (mirrorWindowControllers below).
        let screens = NSScreen.screens
        let pointer = NSEvent.mouseLocation
        let primaryScreen = screens.first { NSMouseInRect(pointer, $0.frame, false) }
            ?? NSScreen.main
            ?? screens.first

        overlayWindowController = OverlayWindowController(frame: primaryScreen?.frame)
        guard let window = overlayWindowController?.window else { return }

        // Use the good SwiftUI overlay with animated effects
        // (soundManager comes via the injected reference — NSApp.delegate is
        // SwiftUI's own wrapper object, not our AppDelegate, so casting it fails)
        guard let soundManager else { return }
        // Rolled once here, not per view, so Surprise wears one palette on every display
        let theme = OverlayWindow.rollTheme(UserDefaults.standard.string(forKey: "visualTheme") ?? "aurora")
        let overlayView = OverlayWindow(theme: theme)
            .environmentObject(self)
            .environmentObject(soundManager)
        
        window.contentView = TransparentHostingView(rootView: overlayView)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.isReleasedWhenClosed = false
        
        // Intercept escape key to prevent system error sound
        // But don't actually do anything - breaks are unskippable!
        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape key
                // Consume the event to prevent error sound
                // Could trigger a visual feedback here if wanted
                NotificationCenter.default.post(name: NotificationName.escapePressed, object: nil)
                return nil // Consume the event
            }
            return event
        }
        
        mirrorWindowControllers = screens
            .filter { $0.frame != primaryScreen?.frame }
            .map { screen in
                let mirror = OverlayWindowController(frame: screen.frame)
                mirror.window?.contentView = TransparentHostingView(rootView: OverlayMirror(theme: theme))
                mirror.window?.isReleasedWhenClosed = false
                return mirror
            }

        // Bring it all the way front
        mirrorWindowControllers.forEach { $0.window?.orderFrontRegardless() }
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)

        // The window server can drop an order-front issued while the app is
        // still settling (launch, wake) — re-assert until it's actually visible
        reassertOverlayVisibility(attempt: 1)
    }

    private func reassertOverlayVisibility(attempt: Int) {
        guard attempt <= 5 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 * Double(attempt)) { [weak self] in
            guard let self = self,
                  self.showingOverlay,
                  let window = self.overlayWindowController?.window,
                  !window.occlusionState.contains(.visible) else { return }
            self.mirrorWindowControllers.forEach { $0.window?.orderFrontRegardless() }
            window.orderFrontRegardless()
            self.reassertOverlayVisibility(attempt: attempt + 1)
        }
    }
    
    private func showHeadsUpNotification(secondsAway: Int = 10) {
        let content = UNMutableNotificationContent()
        content.title = "Break incoming"
        content.body = "Spellbreak lands in \(secondsAway) seconds."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func requestNotificationAuthorizationIfNeeded() {
        guard breakWarningEnabled else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
                // Notifications are optional; denied permission only disables heads-up alerts.
            }
        }
    }

    private func startStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledCommonTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimeRemainingAndWarning()
        }
    }

    private func handleSystemWake() {
        guard timerRunning else { return }
        let elapsed = max(0, Date().timeIntervalSince(lastBreakTime))
        let remaining = breakInterval - elapsed
        let wakeGracePeriod: TimeInterval = 180 // 3 minutes of screen presence after waking
        
        if remaining < wakeGracePeriod {
            // Give user breathing room after opening lid rather than slamming screen immediately
            lastBreakTime = Date().addingTimeInterval(wakeGracePeriod - breakInterval)
            restartTimer()
        } else {
            updateTimeRemainingAndWarning()
        }
    }

    private func updateTimeRemainingAndWarning() {
        checkDailyReset()

        guard timerRunning else {
            // Paused keeps its frozen number (a wake used to zero it on screen)
            timeRemaining = timerPaused ? pausedRemaining : 0
            hideCountdownPill()
            return
        }

        restartIntervalIfMacSlept()
        restartIntervalIfUserCameBack()

        let elapsed = max(0, Date().timeIntervalSince(lastBreakTime))
        let remaining = breakInterval - elapsed

        if remaining <= 0 {
            timeRemaining = 0
            hideCountdownPill()

            if !showingOverlay && !shouldHoldBreak() {
                if scheduledBreaksAllowed {
                    triggerBreak(resetTimerSchedule: true)
                } else {
                    lockScheduledBreaks()
                }
            }
            return
        }

        timeRemaining = remaining
        updateCountdownPill()

        guard breakWarningEnabled,
              scheduledBreaksAllowed,
              !userIsAway,
              !didShowBreakWarning,
              !showingOverlay,
              timeRemaining > 0,
              timeRemaining <= breakWarningLeadTime,
              breakInterval > breakWarningLeadTime else {
            return
        }

        didShowBreakWarning = true
        showHeadsUpNotification(secondsAway: Int(timeRemaining.rounded(.up)))
    }

    /// Show the floating countdown pill during the final seconds before a
    /// break; hide it the moment it no longer applies
    private func updateCountdownPill() {
        let shouldShow = breakWarningEnabled
            && scheduledBreaksAllowed
            && !userIsAway
            && timerRunning
            && !showingOverlay
            && timeRemaining > 0
            && timeRemaining <= breakWarningLeadTime

        guard shouldShow else {
            hideCountdownPill()
            return
        }

        if countdownWindowController == nil {
            countdownWindowController = BreakCountdownWindowController(appState: self)
        }
        countdownWindowController?.window?.orderFrontRegardless()
    }

    private func hideCountdownPill() {
        guard let controller = countdownWindowController else { return }
        countdownWindowController = nil

        guard let window = controller.window else {
            controller.close()
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.35
            window.animator().alphaValue = 0
        }, completionHandler: {
            controller.close()
        })
    }
    
    private func checkDailyReset() {
        let today = DateFormatter.dateOnlyFormatter.string(from: Date())
        if lastBreakDateString != today {
            todayCompletedBreaks = 0
            todaySkippedBreaks = 0
            lastBreakDateString = today
        }
    }
    
    /// Restore timer state after app restart
    private func restoreTimerState() {
        guard timerWasRunning && lastBreakTimestamp > 0 else { return }

        let lastBreak = Date(timeIntervalSince1970: lastBreakTimestamp)
        let elapsed = max(0, Date().timeIntervalSince(lastBreak))
        
        // If we're still within the break interval, restore the timer
        if elapsed < breakInterval {
            lastBreakTime = lastBreak
            timerRunning = true
            requestNotificationAuthorizationIfNeeded()
            
            // Calculate remaining time until next break
            let remainingTime = breakInterval - elapsed
            
            // Set up timer for the remaining time
            timer = Timer.scheduledCommonTimer(withTimeInterval: max(0.1, remainingTime), repeats: false) { [weak self] _ in
                self?.checkAndTriggerBreak()
                // After this break, continue with regular intervals
                guard let self = self else { return }
                self.scheduleRepeatingBreakTimer()
            }
            
            startStatusTimer()
            updateTimeRemainingAndWarning()
        } else {
            // Timer expired while app was closed, trigger break shortly if appropriate
            if elapsed < breakInterval * 2 {
                // Only trigger if we're not too far past the scheduled time
                timerRunning = true
                timerWasRunning = true
                requestNotificationAuthorizationIfNeeded()

                // Land the break a few seconds out instead of mid-launch: a window
                // ordered front before the app finishes launching can stay offscreen,
                // leaving showingOverlay wedged true and blocking all future breaks
                let grace: TimeInterval = 5
                lastBreakTime = Date().addingTimeInterval(grace - breakInterval)
                timer = Timer.scheduledCommonTimer(withTimeInterval: grace, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.checkAndTriggerBreak()
                    self.scheduleRepeatingBreakTimer()
                }

                startStatusTimer()
                updateTimeRemainingAndWarning()
            } else {
                timerWasRunning = false
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
