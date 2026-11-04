//
//  OverlayWindow.swift
//  Spellbreak
//
//  Full-screen break overlay with mystical animated effects,
//  hold-to-skip functionality, and countdown timer.
//

import SwiftUI
import AppKit

// MARK: - Overlay Window
/// Full-screen break overlay with mystical animated effects
struct OverlayWindow: View {
    static let escapePressed = Notification.Name("EscapePressed")
    static let holdSkipChanged = Notification.Name("SpellbreakOverlayHoldSkipChanged")
    static let toggleMute = Notification.Name("SpellbreakOverlayToggleMute")

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var soundManager: SoundManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var opacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var textScale: Double = 1.0
    @State private var timeRemaining: Int = 0
    @State private var countdownTimer: Timer?
    @State private var dismissWorkItem: DispatchWorkItem?
    @State private var closeWorkItem: DispatchWorkItem?
    @State private var skipRingWorkItem: DispatchWorkItem?
    @State private var escapePulseResetWorkItem: DispatchWorkItem?
    @State private var isHoldingToSkip = false
    @State private var holdProgress: Double = 0
    @State private var holdTimer: Timer?
    @State private var breakEndsAt: Date?
    @State private var hasResolvedBreak = false
    @State private var showSkipRing = false
    @State private var isHoveringRing = false
    @State private var escapePulse: Double = 0
    @State private var breakMessage: String = ""
    @State private var notificationObservers: [NSObjectProtocol] = []

    @AppStorage("lockMode") private var lockMode: Bool = false
    @State private var isHoveringMute = false
    @AppStorage("breakDurationSec") private var breakDuration: Double = 20
    @AppStorage("musicEnabled") private var musicEnabled: Bool = false
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"
    @AppStorage("showBreakMessage") private var showBreakMessage: Bool = true
    /// The palette THIS break is wearing. Rolled once per break by AppState and
    /// handed in at init so every display's mirror wears the exact same one.
    @State private var resolvedTheme: String

    init(theme: String) {
        _resolvedTheme = State(initialValue: theme)
    }

    // Calculate required hold duration from break length, clamped 2-15s (2-3s in practice).
    private var requiredHoldDuration: Double {
        let duration = actualBreakDuration / 60.0
        return min(max(duration, 2.0), 15.0)
    }

    private var actualBreakDuration: TimeInterval {
        SpellbreakLimits.clampDuration(breakDuration)
    }

    /// Every named preset palette. "random" rolls a harmonious 4-stop descriptor per break.
    static let concreteThemes = ["aurora", "ember", "violet"]

    static func rollTheme(_ stored: String) -> String {
        guard stored == "random" else { return stored }
        return AuroraPalette.rollHarmoniousDescriptor()
    }

    private var themeGlowColor: Color {
        AuroraPalette.from(theme: resolvedTheme).glowColor
    }

    /// True when ambient sound is actively enabled and playing (stays truthful if
    /// headphones disconnect mid-break and SoundManager silences speaker spill).
    private var isAmbientAudible: Bool {
        musicEnabled && soundManager.isPlaying
    }

    var body: some View {
        ZStack {
            // Warm near-black grounding so the themed colors read as jewel tones.
            Rectangle()
                .fill(Color(red: 0.078, green: 0.062, blue: 0.058))
                .ignoresSafeArea()

            if !reduceTransparency {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .opacity(0.35)
                    .ignoresSafeArea()
            }

            // Single-pass blurred aurora (outer .blur removed; folded into AuroraBackground).
            AuroraBackground(palette: AuroraPalette.from(theme: resolvedTheme))
                .opacity(reduceTransparency ? 0.88 : 0.95)

            // Warm ink tint for legibility + subtle Escape feedback
            Rectangle()
                .fill(Color.spellInk.opacity(0.18 + (reduceMotion ? 0 : escapePulse * 0.12)))
                .ignoresSafeArea()
                .animation(reduceMotion ? nil : .easeOut(duration: 0.8), value: escapePulse)

            AmbientParticles(palette: AuroraPalette.from(theme: resolvedTheme))
                .opacity(0.7)

            // Centered message
            if showBreakMessage {
                Text(breakMessage)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.spellCream, .spellCream.opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .spellCream.opacity(0.30), radius: 20)
                    .shadow(color: .spellCream.opacity(0.16), radius: 40)
                    .shadow(color: themeGlowColor.opacity(0.36), radius: 34)
                    .shadow(color: Color.spellInk.opacity(0.45), radius: 8, x: 0, y: 3)
                    .opacity(messageOpacity * 0.94)
                    .scaleEffect(reduceMotion ? 1.0 : textScale)
                    .padding(.horizontal, 60)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .accessibilityLabel(breakMessage)
            }

            // Unified bottom horizon (mute left, skip ring center, timer right — aligned on one centerline)
            VStack {
                Spacer()

                ZStack {
                    // Center: Hold-to-skip ring
                    if !lockMode {
                        skipRingControl
                    }

                    // Left & right controls pinned to matching horizontal insets
                    HStack(alignment: .center) {
                        muteControl
                        Spacer()
                        if timeRemaining > 0 {
                            countdownReadout
                        }
                    }
                    .padding(.horizontal, 48)
                }
                .frame(height: 64)
                .padding(.bottom, 58)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(opacity)
        .onAppear {
            startBreakPresentation()
        }
        .onChange(of: lockMode) { locked in
            if locked {
                cancelHoldToSkip()
                skipRingWorkItem?.cancel()
                showSkipRing = false
            } else if !hasResolvedBreak && !showSkipRing {
                scheduleSkipRingReveal()
            }
        }
        .onDisappear {
            cleanupScheduledWork()
            soundManager.stopAmbient()
            notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
            notificationObservers.removeAll()
        }
    }

    // MARK: - Bottom Controls

    private var skipRingControl: some View {
        ZStack {
            // Subtle warm-ink scrim so the ring stays legible over bright dawn/day gold waves
            Circle()
                .fill(Color.spellInk.opacity(0.28))
                .frame(width: 64, height: 64)

            Circle()
                .stroke(Color.spellCream.opacity(isHoveringRing ? 0.36 : 0.22), lineWidth: 3)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    Color.spellCream.opacity(0.88),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: holdProgress)

            if isHoldingToSkip && holdProgress > 0 {
                Text("\(Int(holdProgress * 100))")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.spellCream.opacity(0.95))
            } else {
                Text("skip")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.spellCream.opacity(isHoveringRing ? 0.85 : 0.62))
                    .animation(.easeInOut(duration: 0.2), value: isHoveringRing)
            }
        }
        .scaleEffect(reduceMotion ? 1.0 : (isHoldingToSkip ? 1.14 : (isHoveringRing ? 1.05 : 1.0)))
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.3), value: isHoldingToSkip)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isHoveringRing)
        .opacity(showSkipRing ? 1 : 0)
        .allowsHitTesting(showSkipRing && !lockMode)
        .animation(.easeOut(duration: reduceMotion ? 0.25 : 0.5), value: showSkipRing)
        .onHover { hovering in
            isHoveringRing = hovering
        }
        .onLongPressGesture(minimumDuration: requiredHoldDuration, maximumDistance: .infinity) {
            if showSkipRing && !lockMode {
                skipBreak()
            }
        } onPressingChanged: { pressing in
            handleHoldPressingChanged(pressing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(!showSkipRing || lockMode)
        .accessibilityLabel("Skip break")
        .accessibilityHint("Hold Space or activate to end the break early")
        .accessibilityValue(isHoldingToSkip ? "\(Int(holdProgress * 100)) percent" : "")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(.default) {
            if showSkipRing && !lockMode {
                skipBreak()
            }
        }
        .accessibilityAction(named: "Skip break") {
            if showSkipRing && !lockMode {
                skipBreak()
            }
        }
    }

    private var muteControl: some View {
        Button {
            toggleAmbientMute()
        } label: {
            Image(systemName: isAmbientAudible ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.spellCream.opacity(isHoveringMute ? 0.88 : 0.60))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.spellInk.opacity(isHoveringMute ? 0.34 : 0.22))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(reduceMotion ? 1.0 : (isHoveringMute ? 1.08 : 1.0))
        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.3), value: isHoveringMute)
        .animation(.easeOut(duration: 0.2), value: isAmbientAudible)
        .onHover { isHoveringMute = $0 }
        .opacity(messageOpacity * 0.92)
        .accessibilityLabel(isAmbientAudible ? "Mute ambient sound" : "Play ambient sound")
        .help(isAmbientAudible ? "Mute ambient (M)" : "Play ambient (M)")
    }

    private var countdownReadout: some View {
        Text(formatTimeShort(timeRemaining))
            .font(.system(size: 24, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.spellCream.opacity(0.68))
            .shadow(color: Color.spellInk.opacity(0.45), radius: 4, x: 0, y: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.spellInk.opacity(0.20))
            )
            .opacity(messageOpacity * 0.92)
            .accessibilityLabel("\(TimeInterval(timeRemaining).spokenDuration) remaining")
    }

    // MARK: - Lifecycle & Actions

    private func startBreakPresentation() {
        let context = appState.getBreakContext()
        breakMessage = SpellTextGenerator.generateMessage(
            breakCount: context.breakCount,
            skippedCount: context.skippedCount,
            lastBreakInterval: context.lastBreakInterval
        )

        soundManager.playBreakStartChime()
        installNotificationObservers()

        let fadeDuration = reduceMotion ? 0.35 : 1.2
        withAnimation(.easeOut(duration: fadeDuration)) {
            opacity = 1
        }

        withAnimation(.easeOut(duration: reduceMotion ? 0.3 : 1.0).delay(reduceMotion ? 0.05 : 0.3)) {
            messageOpacity = 1
        }

        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.334).repeatForever(autoreverses: true).delay(1.5)) {
                textScale = 1.05
            }
        }

        if musicEnabled {
            soundManager.playAmbient()
        }

        hasResolvedBreak = false
        breakEndsAt = Date().addingTimeInterval(actualBreakDuration)
        updateCountdown()
        startCountdownTimer()
        scheduleSkipRingReveal()
        scheduleAutoCompletion()
        announceBreakForVoiceOver()
    }

    private func installNotificationObservers() {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()

        let escObs = NotificationCenter.default.addObserver(
            forName: Self.escapePressed,
            object: nil,
            queue: .main
        ) { _ in
            cancelHoldToSkip()
            guard !reduceMotion else { return }
            escapePulse = 1
            escapePulseResetWorkItem?.cancel()
            let resetWork = DispatchWorkItem {
                escapePulse = 0
            }
            escapePulseResetWorkItem = resetWork
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: resetWork)
        }

        let holdObs = NotificationCenter.default.addObserver(
            forName: Self.holdSkipChanged,
            object: nil,
            queue: .main
        ) { note in
            let pressing = (note.userInfo?["pressing"] as? Bool) ?? false
            handleHoldPressingChanged(pressing)
        }

        let muteObs = NotificationCenter.default.addObserver(
            forName: Self.toggleMute,
            object: nil,
            queue: .main
        ) { _ in
            toggleAmbientMute()
        }

        notificationObservers = [escObs, holdObs, muteObs]
    }

    private func toggleAmbientMute() {
        if isAmbientAudible {
            musicEnabled = false
            soundManager.stopAmbient()
        } else {
            musicEnabled = true
            soundManager.playAmbient()
        }
    }

    private func handleHoldPressingChanged(_ pressing: Bool) {
        guard showSkipRing && !lockMode && !hasResolvedBreak else {
            if !pressing { cancelHoldToSkip() }
            return
        }
        if pressing {
            guard !isHoldingToSkip else { return }
            isHoldingToSkip = true
            startHoldTimer()
        } else {
            cancelHoldToSkip()
        }
    }

    private func cancelHoldToSkip() {
        isHoldingToSkip = false
        holdTimer?.invalidate()
        holdTimer = nil
        if holdProgress < 1.0 && holdProgress > 0 {
            withAnimation(reduceMotion ? .linear(duration: 0.1) : .spring(duration: 0.3, bounce: 0.4)) {
                holdProgress = 0
            }
        }
    }

    private func announceBreakForVoiceOver() {
        let durationSpeech = actualBreakDuration.spokenDuration
        let messagePart = showBreakMessage && !breakMessage.isEmpty ? "\(breakMessage). " : ""
        let announcement = "Spellbreak pause, \(durationSpeech). \(messagePart)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NSAccessibility.post(
                element: NSApp as Any,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement,
                    .priority: NSAccessibilityPriorityLevel.high.rawValue
                ]
            )
        }
    }

    private func formatTimeShort(_ seconds: Int) -> String {
        if seconds >= 60 {
            let mins = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(seconds)"
        }
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledCommonTimer(withTimeInterval: 0.25, tolerance: 0.05, repeats: true) { timer in
            updateCountdown()
            if timeRemaining <= 0 {
                timer.invalidate()
                countdownTimer = nil
                completeBreak()
            }
        }
    }

    private func updateCountdown() {
        guard let breakEndsAt else {
            timeRemaining = Int(ceil(actualBreakDuration))
            return
        }

        let remaining = max(0, breakEndsAt.timeIntervalSinceNow)
        timeRemaining = Int(ceil(remaining))
    }

    private func scheduleSkipRingReveal() {
        guard !lockMode else { return }

        skipRingWorkItem?.cancel()
        let work = DispatchWorkItem {
            guard !hasResolvedBreak, !lockMode else { return }
            withAnimation(reduceMotion ? .easeOut(duration: 0.25) : .spring(duration: 0.6, bounce: 0.3)) {
                showSkipRing = true
            }
        }

        skipRingWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    private func scheduleAutoCompletion() {
        dismissWorkItem?.cancel()
        let work = DispatchWorkItem {
            completeBreak()
        }

        dismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + actualBreakDuration, execute: work)
    }

    private func scheduleOverlayClose(after delay: TimeInterval) {
        closeWorkItem?.cancel()
        let work = DispatchWorkItem { [weak appState] in
            guard let appState, appState.showingOverlay else { return }
            appState.showingOverlay = false
        }

        closeWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func completeBreak() {
        resolveBreak(asSkipped: false)
    }

    private func skipBreak() {
        resolveBreak(asSkipped: true)
    }

    private func resolveBreak(asSkipped skipped: Bool) {
        guard !hasResolvedBreak, appState.showingOverlay else { return }

        hasResolvedBreak = true
        let mirrorFadeDuration: TimeInterval = reduceMotion ? 0.25 : (skipped ? 0.6 : 1.0)
        NotificationCenter.default.post(
            name: OverlayMirror.fadeOut,
            object: nil,
            userInfo: ["duration": mirrorFadeDuration]
        )
        isHoldingToSkip = false
        holdProgress = 0
        countdownTimer?.invalidate()
        countdownTimer = nil
        holdTimer?.invalidate()
        holdTimer = nil
        dismissWorkItem?.cancel()
        skipRingWorkItem?.cancel()
        escapePulseResetWorkItem?.cancel()
        escapePulse = 0

        if skipped {
            soundManager.playSkipComplete()
            appState.markBreakSkipped()

            withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.4)) {
                messageOpacity = 0
                showSkipRing = false
            }

            withAnimation(.easeInOut(duration: reduceMotion ? 0.25 : 0.6).delay(reduceMotion ? 0 : 0.1)) {
                opacity = 0
            }

            scheduleOverlayClose(after: reduceMotion ? 0.3 : 0.7)
        } else {
            soundManager.playBreakCompleteChime()
            appState.markBreakCompleted()

            withAnimation(.easeInOut(duration: reduceMotion ? 0.25 : 0.8)) {
                messageOpacity = 0
                showSkipRing = false
            }

            withAnimation(.easeInOut(duration: reduceMotion ? 0.3 : 1.0).delay(reduceMotion ? 0 : 0.2)) {
                opacity = 0
            }

            scheduleOverlayClose(after: reduceMotion ? 0.35 : 1.2)
        }

        soundManager.stopAmbient()
    }

    private func cleanupScheduledWork() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        holdTimer?.invalidate()
        holdTimer = nil
        dismissWorkItem?.cancel()
        closeWorkItem?.cancel()
        skipRingWorkItem?.cancel()
        escapePulseResetWorkItem?.cancel()
        isHoldingToSkip = false
        showSkipRing = false
        escapePulse = 0
        breakEndsAt = nil
        dismissWorkItem = nil
        closeWorkItem = nil
        skipRingWorkItem = nil
        escapePulseResetWorkItem = nil
    }

    private func startHoldTimer() {
        holdProgress = 0
        let updateInterval = 0.05
        let increments = requiredHoldDuration / updateInterval

        holdTimer?.invalidate()
        holdTimer = Timer.scheduledCommonTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            if isHoldingToSkip && !lockMode {
                holdProgress = min(holdProgress + (1.0 / increments), 1.0)
                if holdProgress >= 1.0 {
                    timer.invalidate()
                    holdTimer = nil
                    skipBreak()
                }
            } else {
                timer.invalidate()
                holdTimer = nil
                withAnimation(reduceMotion ? .linear(duration: 0.1) : .spring(duration: 0.3, bounce: 0.4)) {
                    holdProgress = 0
                }
            }
        }
    }
}

// MARK: - Overlay Mirror
/// Secondary-display companion during a break: the same aurora at a calm 15fps
/// cadence without particles, text, or interactive chrome.
struct OverlayMirror: View {
    static let fadeOut = Notification.Name("SpellbreakOverlayMirrorFadeOut")

    let theme: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.078, green: 0.062, blue: 0.058))
                .ignoresSafeArea()

            if !reduceTransparency {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .opacity(0.35)
                    .ignoresSafeArea()
            }

            AuroraBackground(
                palette: AuroraPalette.from(theme: theme),
                frameInterval: 1.0 / 15.0
            )
            .opacity(reduceTransparency ? 0.88 : 0.95)

            Rectangle()
                .fill(Color.spellInk.opacity(0.18))
                .ignoresSafeArea()
        }
        .opacity(opacity)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.35 : 1.2)) {
                opacity = 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: OverlayMirror.fadeOut)) { note in
            let duration = (note.userInfo?["duration"] as? TimeInterval) ?? (reduceMotion ? 0.25 : 0.8)
            withAnimation(.easeInOut(duration: duration)) {
                opacity = 0
            }
        }
    }
}
