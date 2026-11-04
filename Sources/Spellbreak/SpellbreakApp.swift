//
//  SpellbreakApp.swift
//  Spellbreak
//
//  Main application entry point managing menu bar presence,
//  overlay presentation, and break scheduling.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Transparent Hosting View
/// Fixes opaque backing issue with NSHostingView over clear windows
final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}

// MARK: - Keyable Borderless Overlay Window
/// Borderless NSWindows refuse key status by default, which lets keyboard input
/// fall through to windows underneath (like Settings). Primary break windows opt
/// into key status; secondary mirror displays stay non-key.
final class OverlayPanelWindow: NSWindow {
    var allowsKeyStatus: Bool = false
    override var canBecomeKey: Bool { allowsKeyStatus }
    override var canBecomeMain: Bool { allowsKeyStatus }
}

// MARK: - Overlay Window Controller
/// Controller for one display's full-screen break overlay. One per display: a
/// single window stretched across them all only ever drew on one, because with
/// "Displays have separate Spaces" on (macOS's default) windows can't span displays.
final class OverlayWindowController: NSWindowController {
    init(frame: NSRect?, allowsKey: Bool) {
        let window = OverlayPanelWindow(
            contentRect: frame ?? NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.allowsKeyStatus = allowsKey
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
/// Keeps AppState in sync with normal macOS window close behavior (including Escape).
final class PreferencesWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }
}

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
@main
struct SpellbreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App State
/// Central state coordinator handling timers, multi-display overlays, and StoreKit gating.
class AppState: ObservableObject {
    static let showTestBreakNotification = Notification.Name("ShowTestBreak")

    // MARK: - Published Properties
    @Published var timerRunning = false
    @Published var showingOverlay = false
    @Published var showingPreferences = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var timerPaused = false

    // MARK: - Dependencies & Controllers
    weak var soundManager: SoundManager?
    weak var store: Store?
    private var timer: Timer?
    private var statusTimer: Timer?
    private var lastBreakTime: Date = Date()
    private var overlayWindowController: OverlayWindowController?
    private var mirrorWindowControllers: [OverlayWindowController] = []
    private var activeOverlayTheme: String = "aurora"
    private var preferencesWindowController: PreferencesWindowController?
    private var preferencesSelectedTab: Int = 0
    private var overlayCancellable: AnyCancellable?
    private var preferencesCancellable: AnyCancellable?
    private var preferencesResizeCancellable: AnyCancellable?
    private var storeAccessCancellable: AnyCancellable?
    private var overlayFailsafe: DispatchWorkItem?
    private var countdownWindowController: BreakCountdownWindowController?
    private var overlayKeyMonitor: Any?
    private var testBreakObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var willSleepObserver: NSObjectProtocol?
    private var screenChangeObserver: NSObjectProtocol?
    private var unlockObserver: NSObjectProtocol?
    private var currentBreakCountsTowardStats = true
    private var currentBreakResetTimerAnchor = true
    private let breakWarningLeadTime: TimeInterval = 15

    // MARK: - Session Context (for message generation)
    private var sessionBreakCount: Int = 0
    private var sessionSkippedCount: Int = 0
    private var lastBreakCompletedTime: Date?

    // MARK: - Persisted Properties
    @AppStorage("breakIntervalMin") private var breakIntervalMinutes: Double = 20.0 {
        didSet {
            if timerRunning {
                restartTimer()
            }
        }
    }
    @AppStorage("timerWasRunning") var timerWasRunning: Bool = false
    @AppStorage("lastBreakTimestamp") private var lastBreakTimestamp: Double = 0
    @AppStorage("deferDuringFullscreen") private var deferDuringFullscreen: Bool = true

    private var pausedRemaining: TimeInterval = 0
    private var lastTickWallClock = Date()
    private var lastTickUptime = ProcessInfo.processInfo.systemUptime
    private var lastAwayPollUptime: TimeInterval = 0
    private var userIsAway = false
    private var typingHoldStartedAt: Date?

    // MARK: - Computed Properties
    private var breakInterval: TimeInterval {
        SpellbreakLimits.clampInterval(breakIntervalMinutes) * 60
    }

    private var currentBreakDurationSec: TimeInterval {
        let raw = UserDefaults.standard.object(forKey: "breakDurationSec") as? Double
            ?? SpellbreakLimits.defaultDurationSec
        return SpellbreakLimits.clampDuration(raw)
    }

    init(soundManager: SoundManager? = nil, store: Store? = nil) {
        self.soundManager = soundManager
        self.store = store

        setupCombineObservers()
        bindStoreAccess()
        restoreTimerState()

        // Debug hook: SPELLBREAK_FIRE_NOW=1 fires a test break 3s after launch
        if ProcessInfo.processInfo.environment["SPELLBREAK_FIRE_NOW"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.triggerBreak(countsTowardStats: false, resetsTimerAnchor: false)
            }
        }

        testBreakObserver = NotificationCenter.default.addObserver(
            forName: Self.showTestBreakNotification,
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

        willSleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.soundManager?.stopAmbientImmediately()
            if self.showingOverlay {
                self.showingOverlay = false
            }
        }

        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenParametersChanged()
        }

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
        if let observer = willSleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = unlockObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let monitor = overlayKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }

        overlayCancellable?.cancel()
        preferencesCancellable?.cancel()
        preferencesResizeCancellable?.cancel()
        storeAccessCancellable?.cancel()
    }

    private func bindStoreAccess() {
        guard let store else { return }
        storeAccessCancellable = store.$access
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // If StoreKit resolves to .notStarted / .trialEnded (e.g. after a launch
                // restore or trial expiry or refund), halt scheduled timers cleanly.
                if (self.timerRunning || self.timerPaused) && !self.scheduledBreaksAllowed {
                    self.stopTimer()
                }
            }
    }

    func startTimer() {
        guard scheduledBreaksAllowed else {
            showPreferences()
            return
        }
        stopTimer()
        timerRunning = true
        lastBreakTime = Date()
        timeRemaining = breakInterval

        timerWasRunning = true
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970

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
        hideCountdownPill()

        timerWasRunning = false
    }

    private func shouldHoldBreak() -> Bool {
        if userIsAway { return true }
        guard deferDuringFullscreen else { return false }
        return ScreenBusy.isBusy() || isMidSentence()
    }

    private func isMidSentence() -> Bool {
        let activelyTypingOrDragging = ScreenBusy.secondsSinceLastKeystroke() < 2
            || ScreenBusy.isMouseButtonDown()
        guard activelyTypingOrDragging else {
            typingHoldStartedAt = nil
            return false
        }
        let started = typingHoldStartedAt ?? Date()
        typingHoldStartedAt = started
        return Date().timeIntervalSince(started) < 30
    }

    @discardableResult
    private func restartIntervalIfUserCameBack() -> Bool {
        let idleSeconds = ScreenBusy.secondsSinceLastInput()
        let awayThreshold = max(3 * 60, currentBreakDurationSec)

        if idleSeconds >= awayThreshold {
            // Poll IOPMCopyAssertionsStatus at most once every 5s while idle so background
            // powerd IPC stays negligible.
            let nowUptime = ProcessInfo.processInfo.systemUptime
            if !userIsAway && (nowUptime - lastAwayPollUptime >= 5) {
                lastAwayPollUptime = nowUptime
                if !ScreenBusy.displayIsHeldAwake() {
                    userIsAway = true
                }
            }
            if userIsAway {
                return false
            }
        }

        guard userIsAway else { return false }
        userIsAway = false

        guard timerRunning else { return false }
        lastBreakTime = Date()
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        scheduleRepeatingBreakTimer()
        return true
    }

    func pauseTimer() {
        guard timerRunning else { return }

        let remaining = max(0, breakInterval - Date().timeIntervalSince(lastBreakTime))
        stopTimer()
        pausedRemaining = remaining
        timerPaused = true
        timeRemaining = remaining
    }

    func resumeTimer() {
        guard scheduledBreaksAllowed else {
            showPreferences()
            return
        }
        let remaining = pausedRemaining > 0 ? pausedRemaining : breakInterval

        timerPaused = false
        pausedRemaining = 0
        startTimer()

        lastBreakTime = Date().addingTimeInterval(remaining - breakInterval)
        lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        updateTimeRemainingAndWarning()
    }

    func toggleTimer() {
        if timerRunning {
            pauseTimer()
        } else if scheduledBreaksAllowed {
            resumeTimer()
        } else {
            showPreferences()
        }
    }

    private var scheduledBreaksAllowed: Bool {
        store?.allowsScheduledBreaks ?? true
    }

    private func lockScheduledBreaks() {
        stopTimer()
        showPreferences()
    }

    private func restartTimer() {
        stopTimer()
        startTimer()
    }

    private func scheduleRepeatingBreakTimer() {
        timer?.invalidate()
        timer = Timer.scheduledCommonTimer(
            withTimeInterval: max(0.1, breakInterval),
            tolerance: 1.0,
            repeats: true
        ) { [weak self] _ in
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

    @discardableResult
    private func restartIntervalIfMacSlept() -> Bool {
        let now = Date()
        let uptime = ProcessInfo.processInfo.systemUptime
        let slept = now.timeIntervalSince(lastTickWallClock) - (uptime - lastTickUptime)
        lastTickWallClock = now
        lastTickUptime = uptime

        guard timerRunning, slept >= max(60, currentBreakDurationSec) else { return false }

        lastBreakTime = now
        lastBreakTimestamp = now.timeIntervalSince1970
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
        currentBreakResetTimerAnchor = resetsTimerAnchor
        typingHoldStartedAt = nil

        if resetsTimerAnchor {
            lastBreakTime = Date()
            lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
        }

        if timerRunning && resetTimerSchedule {
            scheduleRepeatingBreakTimer()
        }

        hideCountdownPill()
        showingOverlay = true
        showOverlayWindow()
        armOverlayFailsafe()
    }

    private func armOverlayFailsafe() {
        overlayFailsafe?.cancel()
        let failsafe = DispatchWorkItem { [weak self] in
            guard let self = self, self.showingOverlay else { return }
            self.showingOverlay = false
        }
        overlayFailsafe = failsafe
        DispatchQueue.main.asyncAfter(deadline: .now() + currentBreakDurationSec + 30, execute: failsafe)
    }

    func markBreakCompleted() {
        guard currentBreakCountsTowardStats else {
            currentBreakCountsTowardStats = true
            return
        }

        sessionBreakCount += 1
        lastBreakCompletedTime = Date()
    }

    func markBreakSkipped() {
        guard currentBreakCountsTowardStats else {
            currentBreakCountsTowardStats = true
            return
        }

        sessionSkippedCount += 1
    }

    func getBreakContext() -> (breakCount: Int, skippedCount: Int, lastBreakInterval: TimeInterval?) {
        let interval: TimeInterval? = lastBreakCompletedTime.map { Date().timeIntervalSince($0) }
        return (sessionBreakCount, sessionSkippedCount, interval)
    }

    private func setupCombineObservers() {
        overlayCancellable = $showingOverlay
            .removeDuplicates()
            .sink { [weak self] showing in
                guard let self else { return }
                if !showing {
                    self.overlayFailsafe?.cancel()
                    self.overlayFailsafe = nil
                    if let monitor = self.overlayKeyMonitor {
                        NSEvent.removeMonitor(monitor)
                        self.overlayKeyMonitor = nil
                    }
                    self.overlayWindowController?.close()
                    self.overlayWindowController = nil
                    self.mirrorWindowControllers.forEach { $0.close() }
                    self.mirrorWindowControllers = []

                    // If a Test Break just ended right before a scheduled break was due,
                    // grant a 60s cushion so a second break doesn't fire 1 second later.
                    if !self.currentBreakResetTimerAnchor && self.timerRunning {
                        let elapsed = max(0, Date().timeIntervalSince(self.lastBreakTime))
                        let remaining = self.breakInterval - elapsed
                        let postTestGrace: TimeInterval = 60
                        if remaining < postTestGrace {
                            self.lastBreakTime = Date().addingTimeInterval(postTestGrace - self.breakInterval)
                            self.lastBreakTimestamp = self.lastBreakTime.timeIntervalSince1970
                            self.scheduleRepeatingBreakTimer()
                            self.updateTimeRemainingAndWarning()
                        }
                    }
                    self.currentBreakResetTimerAnchor = true
                }
            }

        preferencesCancellable = $showingPreferences
            .removeDuplicates()
            .sink { [weak self] showing in
                if !showing {
                    self?.preferencesResizeCancellable?.cancel()
                    self?.preferencesResizeCancellable = nil
                    guard let controller = self?.preferencesWindowController else { return }
                    self?.preferencesWindowController = nil
                    controller.close()
                }
            }
    }

    func showPreferences(selectingTab tab: Int? = nil) {
        if let tab {
            preferencesSelectedTab = tab
        }
        showingPreferences = true

        if preferencesWindowController == nil {
            guard let soundManager, let store else { return }
            let preferences = PreferencesView(initialTab: preferencesSelectedTab)
                .environmentObject(soundManager)
                .environmentObject(store)

            let styleMask: NSWindow.StyleMask = [.titled, .closable]
            let titleBarHeight = NSWindow.frameRect(forContentRect: .zero, styleMask: styleMask).height
            let fittingHeight = NSHostingView(rootView: preferences).fittingSize.height
            let availableHeight = max(480, (NSScreen.main?.visibleFrame.height ?? .greatestFiniteMagnitude) - titleBarHeight)
            let contentHeight = min(fittingHeight, availableHeight)

            let window = PreferencesWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: contentHeight),
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = "Spellbreak Settings"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(red: 0.16, green: 0.14, blue: 0.22, alpha: 1.0)
            applyPreferencesContentView(to: window, rootView: preferences, fittingHeight: fittingHeight, availableHeight: availableHeight)
            window.center()
            window.collectionBehavior = [.moveToActiveSpace]
            window.isMovableByWindowBackground = false
            window.styleMask.remove(.resizable)

            preferencesWindowController = PreferencesWindowController(window: window) { [weak self] in
                self?.handlePreferencesWindowClosed()
            }

            // Re-fit smoothly whenever StoreKit resolves trial/unlock state or products load
            // so the unlock row & caption never clip at the bottom on first launch.
            preferencesResizeCancellable = Publishers.CombineLatest3(
                store.$access,
                store.$unlockProduct,
                store.$problem
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.refitPreferencesWindowIfNeeded()
            }
        } else if let tab {
            NotificationCenter.default.post(
                name: PreferencesView.selectTabNotification,
                object: nil,
                userInfo: ["tab": tab]
            )
        }

        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func applyPreferencesContentView<V: View>(
        to window: NSWindow,
        rootView: V,
        fittingHeight: CGFloat,
        availableHeight: CGFloat
    ) {
        let contentHeight = min(fittingHeight, availableHeight)
        if fittingHeight > availableHeight {
            window.contentView = NSHostingView(
                rootView: ScrollView { rootView }
                    .frame(width: 560, height: contentHeight)
            )
        } else {
            window.contentView = NSHostingView(rootView: rootView)
        }
    }

    private func refitPreferencesWindowIfNeeded() {
        guard let window = preferencesWindowController?.window,
              let soundManager,
              let store else { return }

        let probe = PreferencesView(initialTab: preferencesSelectedTab)
            .environmentObject(soundManager)
            .environmentObject(store)
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let titleBarHeight = NSWindow.frameRect(forContentRect: .zero, styleMask: styleMask).height
        let screen = window.screen ?? NSScreen.main
        let availableHeight = max(480, (screen?.visibleFrame.height ?? .greatestFiniteMagnitude) - titleBarHeight)
        let fittingHeight = NSHostingView(rootView: probe).fittingSize.height
        let targetContentHeight = min(fittingHeight, availableHeight)
        let currentContentHeight = window.contentLayoutRect.height

        guard abs(targetContentHeight - currentContentHeight) > 2 else { return }

        // Keep top-left corner anchored while growing/shrinking downward, clamped onto visibleFrame
        let oldFrame = window.frame
        var newFrame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: 560, height: targetContentHeight))
        newFrame.origin.x = oldFrame.origin.x
        newFrame.origin.y = oldFrame.maxY - newFrame.height
        if let visible = screen?.visibleFrame, newFrame.minY < visible.minY {
            newFrame.origin.y = visible.minY
        }
        window.setFrame(newFrame, display: true, animate: false)
    }

    private func handlePreferencesWindowClosed() {
        preferencesResizeCancellable?.cancel()
        preferencesResizeCancellable = nil
        preferencesWindowController = nil
        if showingPreferences {
            showingPreferences = false
        }
    }

    private func showOverlayWindow() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            showingOverlay = false
            return
        }
        let pointer = NSEvent.mouseLocation
        let primaryScreen = screens.first { NSMouseInRect(pointer, $0.frame, false) }
            ?? NSScreen.main
            ?? screens.first

        overlayWindowController = OverlayWindowController(frame: primaryScreen?.frame, allowsKey: true)
        guard let window = overlayWindowController?.window,
              let soundManager else {
            showingOverlay = false
            return
        }

        let theme = OverlayWindow.rollTheme(UserDefaults.standard.string(forKey: "visualTheme") ?? "aurora")
        activeOverlayTheme = theme
        let overlayView = OverlayWindow(theme: theme)
            .environmentObject(self)
            .environmentObject(soundManager)

        window.contentView = TransparentHostingView(rootView: overlayView)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.isReleasedWhenClosed = false

        installOverlayKeyMonitor()
        rebuildMirrorWindows(screens: screens, excluding: primaryScreen, theme: theme)

        mirrorWindowControllers.forEach { $0.window?.orderFrontRegardless() }
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)

        reassertOverlayVisibility(attempt: 1)
    }

    private func installOverlayKeyMonitor() {
        if let existing = overlayKeyMonitor {
            NSEvent.removeMonitor(existing)
            overlayKeyMonitor = nil
        }

        overlayKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, self.showingOverlay else { return event }

            // Allow standard Command shortcuts (e.g. Command-Q) through untouched
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) {
                return event
            }

            switch event.keyCode {
            case 53: // Escape — gentle pulse, never system beep
                if event.type == .keyDown && !event.isARepeat {
                    NotificationCenter.default.post(name: OverlayWindow.escapePressed, object: nil)
                }
                return nil
            case 49: // Space — hold to skip (accessibility & keyboard parity with pointer hold)
                if event.type == .keyDown && !event.isARepeat {
                    NotificationCenter.default.post(
                        name: OverlayWindow.holdSkipChanged,
                        object: nil,
                        userInfo: ["pressing": true]
                    )
                } else if event.type == .keyUp {
                    NotificationCenter.default.post(
                        name: OverlayWindow.holdSkipChanged,
                        object: nil,
                        userInfo: ["pressing": false]
                    )
                }
                return nil
            case 46: // M — mute/unmute ambient audio during a break
                if event.type == .keyDown && !event.isARepeat {
                    NotificationCenter.default.post(name: OverlayWindow.toggleMute, object: nil)
                }
                return nil
            default:
                // Swallow stray keys during a break so they neither leak into Settings
                // behind the overlay nor trigger NSBeep().
                return nil
            }
        }
    }

    private func rebuildMirrorWindows(screens: [NSScreen], excluding primaryScreen: NSScreen?, theme: String) {
        mirrorWindowControllers.forEach { $0.close() }
        mirrorWindowControllers = screens
            .filter { $0.frame != primaryScreen?.frame }
            .map { screen in
                let mirror = OverlayWindowController(frame: screen.frame, allowsKey: false)
                mirror.window?.contentView = TransparentHostingView(rootView: OverlayMirror(theme: theme))
                mirror.window?.isReleasedWhenClosed = false
                return mirror
            }
    }

    /// Keep the interactive primary break window on a live display if monitors
    /// connect, disconnect, or enter clamshell mode mid-break.
    private func handleScreenParametersChanged() {
        if showingPreferences {
            refitPreferencesWindowIfNeeded()
        }
        guard showingOverlay else { return }

        let screens = NSScreen.screens
        guard let targetScreen = screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main
            ?? screens.first,
              let primaryWindow = overlayWindowController?.window else {
            showingOverlay = false
            return
        }

        primaryWindow.setFrame(targetScreen.frame, display: true)
        rebuildMirrorWindows(screens: screens, excluding: targetScreen, theme: activeOverlayTheme)
        mirrorWindowControllers.forEach { $0.window?.orderFrontRegardless() }
        primaryWindow.orderFrontRegardless()
        primaryWindow.makeKeyAndOrderFront(self)
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

    private func startStatusTimer() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledCommonTimer(
            withTimeInterval: 1.0,
            tolerance: 0.25,
            repeats: true
        ) { [weak self] _ in
            self?.updateTimeRemainingAndWarning()
        }
    }

    private func handleSystemWake() {
        guard timerRunning else { return }
        if !restartIntervalIfMacSlept() {
            let elapsed = max(0, Date().timeIntervalSince(lastBreakTime))
            let remaining = breakInterval - elapsed
            let wakeGracePeriod: TimeInterval = 180
            if remaining < wakeGracePeriod {
                lastBreakTime = Date().addingTimeInterval(wakeGracePeriod - breakInterval)
                lastBreakTimestamp = lastBreakTime.timeIntervalSince1970
                scheduleRepeatingBreakTimer()
            }
        }
        updateTimeRemainingAndWarning()
    }

    private func updateTimeRemainingAndWarning() {
        guard timerRunning else {
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
    }

    /// Show the floating countdown pill during the final seconds before a
    /// break; hide it when busy or away so it never photobombs fullscreen apps or calls.
    private func updateCountdownPill() {
        let shouldShow = scheduledBreaksAllowed
            && !userIsAway
            && timerRunning
            && !showingOverlay
            && timeRemaining > 0
            && timeRemaining <= breakWarningLeadTime
            && breakInterval > breakWarningLeadTime
            && !shouldHoldBreak()

        guard shouldShow else {
            hideCountdownPill()
            return
        }

        if countdownWindowController == nil {
            countdownWindowController = BreakCountdownWindowController(appState: self)
        } else {
            countdownWindowController?.updateScreenPositionIfNeeded()
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

    private func restoreTimerState() {
        guard timerWasRunning && lastBreakTimestamp > 0 else { return }
        guard scheduledBreaksAllowed else {
            timerWasRunning = false
            return
        }

        let lastBreak = Date(timeIntervalSince1970: lastBreakTimestamp)
        let elapsed = max(0, Date().timeIntervalSince(lastBreak))

        if elapsed < breakInterval {
            lastBreakTime = lastBreak
            timerRunning = true

            let remainingTime = breakInterval - elapsed
            timer = Timer.scheduledCommonTimer(
                withTimeInterval: max(0.1, remainingTime),
                tolerance: 0.5,
                repeats: false
            ) { [weak self] _ in
                self?.checkAndTriggerBreak()
                guard let self = self, self.timerRunning else { return }
                self.scheduleRepeatingBreakTimer()
            }

            startStatusTimer()
            updateTimeRemainingAndWarning()
        } else if elapsed < breakInterval * 2 {
            timerRunning = true
            timerWasRunning = true

            let grace: TimeInterval = 5
            lastBreakTime = Date().addingTimeInterval(grace - breakInterval)
            timer = Timer.scheduledCommonTimer(withTimeInterval: grace, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.checkAndTriggerBreak()
                if self.timerRunning {
                    self.scheduleRepeatingBreakTimer()
                }
            }

            startStatusTimer()
            updateTimeRemainingAndWarning()
        } else {
            timerWasRunning = false
        }
    }
}
