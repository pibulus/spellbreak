//
//  PreferencesView.swift
//  Spellbreak
//
//  Settings interface for configuring break intervals,
//  duration, sounds, and other preferences.
//

import SwiftUI
import ServiceManagement
import AppKit

// MARK: - Frosted Card Background
private struct FrostedCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var fillOpacity: Double = 0.06
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    reduceTransparency
                        ? Color(red: 0.21, green: 0.18, blue: 0.28)
                        : Color.spellCream.opacity(fillOpacity)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.spellCream.opacity(reduceTransparency ? 0.18 : 0.09), lineWidth: 1)
                )
        )
    }
}

extension View {
    func frostedCard(cornerRadius: CGFloat = 24, fillOpacity: Double = 0.06) -> some View {
        modifier(FrostedCard(cornerRadius: cornerRadius, fillOpacity: fillOpacity))
    }
}

// MARK: - Preferences View
struct PreferencesView: View {
    static let selectTabNotification = Notification.Name("SpellbreakSelectPreferencesTab")

    // MARK: - UI Constants
    private enum UI {
        static let sidePadding: CGFloat = 32
        static let windowPaddingTop: CGFloat = 8
        static let windowPaddingBottom: CGFloat = 26
        static let sectionSpacing: CGFloat = 16
        static let tabBodyMinHeight: CGFloat = 420
        static let buttonSpacing: CGFloat = 18
        static let buttonHeight: CGFloat = 46
        static let cardPadding: CGFloat = 16
    }

    // MARK: - Core Settings
    @AppStorage("breakIntervalMin") private var breakIntervalMin: Double = 20
    @AppStorage("breakDurationSec") private var breakDurationSec: Double = 20
    @AppStorage("lockMode") private var lockMode: Bool = false
    @AppStorage("deferDuringFullscreen") private var deferDuringFullscreen: Bool = true
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"
    @AppStorage("showBreakMessage") private var showBreakMessage: Bool = true
    @AppStorage("musicEnabled") private var musicEnabled: Bool = false
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true

    // MARK: - UI State
    @State private var selectedTab = 0
    @State private var hoveredElement: String? = nil
    @State private var testButtonPressed = false
    @State private var sparkleRotation: Double = 0
    @State private var titleOffset: CGFloat = 0
    @State private var launchAtLogin: Bool = false
    @State private var launchAtLoginStatus: SMAppService.Status = SMAppService.mainApp.status
    @State private var launchAtLoginError: String?
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var store: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: UI.sectionSpacing) {
                // Signature header — sits cleanly below the hidden-title traffic lights
                HStack(spacing: 11) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.spellPink,
                                    Color.spellCoral
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(sparkleRotation))
                        .accessibilityHidden(true)
                        .onAppear {
                            guard !reduceMotion else { return }
                            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                                sparkleRotation = 8
                            }
                        }

                    Text("Spellbreak")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.spellCream)
                        .offset(y: titleOffset)
                        .onAppear {
                            guard !reduceMotion else { return }
                            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                titleOffset = -2
                            }
                        }

                    Spacer()
                }
                .padding(.horizontal, UI.sidePadding)
                .padding(.bottom, 6)

                // Tab selector
                HStack(spacing: 16) {
                    TabButton(
                        icon: "clock",
                        title: "Time",
                        isSelected: selectedTab == 0,
                        isHovered: hoveredElement == "timer-tab"
                    ) {
                        if selectedTab != 0 {
                            soundManager.playToggleOn()
                        }
                        selectedTab = 0
                    }
                    .onHover { hovering in
                        setHover("timer-tab", hovering)
                    }

                    TabButton(
                        icon: "waveform",
                        title: "Vibes",
                        isSelected: selectedTab == 1,
                        isHovered: hoveredElement == "vibes-tab"
                    ) {
                        if selectedTab != 1 {
                            soundManager.playToggleOn()
                        }
                        selectedTab = 1
                    }
                    .onHover { hovering in
                        setHover("vibes-tab", hovering)
                    }

                    TabButton(
                        icon: "info.circle",
                        title: "About",
                        isSelected: selectedTab == 2,
                        isHovered: hoveredElement == "about-tab"
                    ) {
                        if selectedTab != 2 {
                            soundManager.playToggleOn()
                        }
                        selectedTab = 2
                    }
                    .onHover { hovering in
                        setHover("about-tab", hovering)
                    }
                }
                .padding(.horizontal, UI.sidePadding)

                // Lower canvas: Time & Vibes share tabBodyMinHeight + Test Break;
                // About keeps its cat signature in every mode and adds the unlock row only when needed.
                if selectedTab == 2 && !needsUnlock {
                    aboutFullCanvas
                        .frame(minHeight: UI.tabBodyMinHeight + UI.buttonSpacing + UI.buttonHeight, alignment: .top)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            if selectedTab == 0 {
                                timerContent
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .transition(.opacity)
                            } else if selectedTab == 1 {
                                vibesContent
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .transition(.opacity)
                            } else {
                                aboutFullCanvas
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .transition(.opacity)
                            }
                        }
                        .frame(minHeight: UI.tabBodyMinHeight, alignment: .top)

                        VStack(spacing: 10) {
                            HStack(spacing: 12) {
                                if selectedTab != 2 {
                                    testBreakButton
                                }
                                if needsUnlock {
                                    unlockButton
                                }
                            }
                            if needsUnlock {
                                unlockCaption
                            }
                        }
                        .padding(.top, UI.buttonSpacing)
                        .padding(.horizontal, UI.sidePadding)
                    }
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: selectedTab)
        }
        .padding(.top, UI.windowPaddingTop)
        .padding(.bottom, UI.windowPaddingBottom)
        .frame(width: 560)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.14, blue: 0.22),
                        Color(red: 0.12, green: 0.10, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if !reduceTransparency {
                    Color.spellCream.opacity(0.02)
                        .background(.ultraThinMaterial)
                        .opacity(0.3)
                }
            }
        )
        .onAppear {
            clampStoredTimingsIfNeeded()
            refreshLaunchAtLoginState()
            #if APP_STORE
            if store.trialProduct == nil || store.unlockProduct == nil {
                Task { await store.loadProducts() }
            }
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLaunchAtLoginState()
        }
        .onReceive(NotificationCenter.default.publisher(for: Self.selectTabNotification)) { note in
            if let tab = note.userInfo?["tab"] as? Int, (0...2).contains(tab) {
                selectedTab = tab
            }
        }
    }

    private func setHover(_ key: String, _ hovering: Bool) {
        if hovering {
            hoveredElement = key
        } else if hoveredElement == key {
            hoveredElement = nil
        }
    }

    private func clampStoredTimingsIfNeeded() {
        let clampedInterval = SpellbreakLimits.clampInterval(breakIntervalMin)
        if clampedInterval != breakIntervalMin {
            breakIntervalMin = clampedInterval
        }
        let clampedDuration = SpellbreakLimits.clampDuration(breakDurationSec)
        if clampedDuration != breakDurationSec {
            breakDurationSec = clampedDuration
        }
    }

    // MARK: - Test Break & Unlock
    private var testBreakButton: some View {
        Button(action: {
            testButtonPressed = true
            soundManager.playButtonPress()
            NotificationCenter.default.post(name: AppState.showTestBreakNotification, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                testButtonPressed = false
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .accessibilityHidden(true)
                Text("Test Break")
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
            }
            .foregroundColor(.spellInk)
            .frame(maxWidth: .infinity)
            .frame(height: UI.buttonHeight)
            .background(
                LinearGradient(
                    colors: [
                        Color.spellPink,
                        Color.spellPeach,
                        Color(red: 1.0, green: 0.8, blue: 0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .scaleEffect(reduceMotion ? 1.0 : (testButtonPressed ? 0.98 : (hoveredElement == "test-button" ? 1.01 : 1.0)))
            .shadow(color: Color.spellInk.opacity(hoveredElement == "test-button" ? 0.40 : 0.22),
                    radius: hoveredElement == "test-button" ? 12 : 8,
                    x: 0, y: 4)
            .animation(.easeOut(duration: 0.15), value: hoveredElement == "test-button")
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            setHover("test-button", hovering)
        }
    }

    /// Paying (and website) users never see any of this: the row is just Test Break
    private var needsUnlock: Bool {
        switch store.currentAccess {
        case .notStarted, .trial, .trialEnded: return true
        case .checking, .unlocked: return false
        }
    }

    /// Start the free week, or unlock once it's running or done. If the Mac launched
    /// offline (e.g. login item before Wi-Fi associates), clicking retries product loading
    /// rather than leaving the button permanently dead.
    private var unlockButton: some View {
        let startingTrial = store.currentAccess == .notStarted
        let productsReady = store.unlockProduct != nil && (!startingTrial || store.trialProduct != nil)
        let title: String
        let iconName: String

        if !productsReady {
            title = store.isWorking ? "Connecting…" : "Load App Store"
            iconName = "arrow.clockwise"
        } else if startingTrial {
            title = "Try Free for 7 Days"
            iconName = "sparkles"
        } else if let price = store.unlockProduct?.displayPrice {
            title = "Unlock · \(price)"
            iconName = "lock.open.fill"
        } else {
            title = "Unlock"
            iconName = "lock.open.fill"
        }

        let isHovered = hoveredElement == "unlock-button"

        return Button {
            soundManager.playButtonPress()
            Task {
                if !productsReady {
                    await store.loadProducts()
                } else if startingTrial {
                    await store.startTrial()
                } else {
                    await store.unlock()
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .bold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.spellCream)
            .frame(maxWidth: .infinity)
            .frame(height: UI.buttonHeight)
            .background(Capsule().fill(Color.spellCream.opacity(isHovered ? 0.14 : 0.08)))
            .overlay(
                Capsule().stroke(
                    LinearGradient(colors: [Color.spellPink, Color.spellPeach], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 2
                )
            )
            .scaleEffect(reduceMotion ? 1.0 : (isHovered && !store.isWorking ? 1.01 : 1.0))
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .disabled(store.isWorking)
        .opacity(store.isWorking ? 0.55 : 1)
        .onHover { hovering in
            setHover("unlock-button", hovering)
        }
    }

    private var unlockCaption: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(unlockCaptionText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.spellCream.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Restore Purchase") {
                Task { await store.restore() }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.spellCoral)
            .disabled(store.isWorking)
        }
        .padding(.horizontal, 4)
    }

    /// Before the trial starts, App Review wants three things in plain sight (3.1.1):
    /// how long it lasts, what stops when it ends, and what unlocking costs.
    private var unlockCaptionText: String {
        if let problem = store.problem {
            return problem
        }
        let price = store.unlockProduct?.displayPrice
        switch store.currentAccess {
        case .notStarted:
            let then = price.map { "then \($0) once to keep them" } ?? "then a one-time unlock to keep them"
            return "Scheduled breaks are free for 7 days, \(then). Test Break always works."
        case .trial:
            let days = store.trialDaysLeft ?? 1
            return "Free trial: \(days) \(days == 1 ? "day" : "days") left. Scheduled breaks pause afterward until unlocked."
        case .trialEnded:
            return "The free week has ended. Scheduled breaks pause until unlocked; Test Break still works."
        case .checking, .unlocked:
            return ""
        }
    }

    // MARK: - Timer Tab Content
    private var timerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main timing card
            VStack(spacing: 26) {
                // Break interval
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Every")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.spellCream.opacity(0.9))
                        Spacer()
                        Text("\(Int(SpellbreakLimits.clampInterval(breakIntervalMin)))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.spellPink,
                                        Color.spellCoral
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("minutes")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.spellCream.opacity(0.72))
                    }
                    .accessibilityHidden(true)

                    GradientSlider(
                        value: $breakIntervalMin,
                        options: [15, 20, 25, 30, 45, 60, 90, 120, 180],
                        accessibilityLabel: "Break interval",
                        accessibilityValueFormatter: { "Every \(Int($0)) minutes" },
                        soundManager: soundManager
                    )
                }

                // Break duration
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("For")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.spellCream.opacity(0.9))
                        Spacer()
                        Text("\(Int(SpellbreakLimits.clampDuration(breakDurationSec)))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.7, blue: 0.4),
                                        Color(red: 1.0, green: 0.5, blue: 0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("seconds")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.spellCream.opacity(0.72))
                    }
                    .accessibilityHidden(true)

                    GradientSlider(
                        value: $breakDurationSec,
                        options: [10, 15, 20, 30, 60, 90, 120, 180],
                        accessibilityLabel: "Break duration",
                        accessibilityValueFormatter: { "For \(Int($0)) seconds" },
                        soundManager: soundManager
                    )
                }
            }
            .padding(UI.cardPadding)
            .frostedCard(fillOpacity: hoveredElement == "timing-card" ? 0.10 : 0.06)
            .scaleEffect(reduceMotion ? 1.0 : (hoveredElement == "timing-card" ? 1.005 : 1.0))
            .animation(.easeOut(duration: 0.2), value: hoveredElement == "timing-card")
            .onHover { hovering in
                setHover("timing-card", hovering)
            }
            .padding(.horizontal, UI.sidePadding)

            // Rule-of-three behaviour card: Lock mode, Pause while busy, Autostart.
            VStack(spacing: 0) {
                ToggleRow(
                    title: "Lock mode",
                    subtitle: "Hide the hold-to-skip control",
                    isOn: lockMode,
                    soundManager: soundManager
                ) { lockMode = $0 }

                rowDivider

                ToggleRow(
                    title: "Pause while busy",
                    subtitle: "Waits out fullscreen apps, calls, and active typing",
                    isOn: deferDuringFullscreen,
                    soundManager: soundManager
                ) { deferDuringFullscreen = $0 }

                rowDivider

                ToggleRow(
                    title: "Autostart",
                    subtitle: launchAtLoginSubtitle,
                    isOn: launchAtLogin,
                    soundManager: soundManager
                ) { handleLaunchAtLoginToggle($0) }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, UI.cardPadding)
            .frostedCard(cornerRadius: 20)
            .padding(.horizontal, UI.sidePadding)

            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.spellPeach)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, UI.sidePadding + 4)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(Color.spellCream.opacity(0.07))
    }

    // MARK: - Vibes Tab Content
    private var vibesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Visual Theme")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.spellCream.opacity(0.9))
                    .padding(.horizontal, 4)

                HStack(spacing: 9) {
                    ThemeChip(
                        title: "Aurora",
                        subtitle: "Shifts with the hour",
                        colors: [
                            Color(red: 0.94, green: 0.58, blue: 0.37),
                            Color(red: 0.94, green: 0.31, blue: 0.61),
                            Color(red: 0.66, green: 0.30, blue: 0.98)
                        ],
                        isSelected: visualTheme == "aurora",
                        isHovered: hoveredElement == "theme-aurora"
                    ) {
                        visualTheme = "aurora"
                        soundManager.playToggleOn()
                    }
                    .onHover { hovering in
                        setHover("theme-aurora", hovering)
                    }

                    ThemeChip(
                        title: "Ember",
                        subtitle: "Warm dusk colours all day",
                        colors: [
                            Color(red: 1.00, green: 0.75, blue: 0.25),
                            Color(red: 1.00, green: 0.45, blue: 0.10),
                            Color(red: 0.92, green: 0.25, blue: 0.18)
                        ],
                        isSelected: visualTheme == "ember",
                        isHovered: hoveredElement == "theme-ember"
                    ) {
                        visualTheme = "ember"
                        soundManager.playToggleOn()
                    }
                    .onHover { hovering in
                        setHover("theme-ember", hovering)
                    }

                    ThemeChip(
                        title: "Violet",
                        subtitle: "Cool night colours all day",
                        colors: [
                            Color(red: 0.42, green: 0.36, blue: 1.00),
                            Color(red: 0.58, green: 0.18, blue: 0.98),
                            Color(red: 0.11, green: 0.07, blue: 0.42)
                        ],
                        isSelected: visualTheme == "violet",
                        isHovered: hoveredElement == "theme-violet"
                    ) {
                        visualTheme = "violet"
                        soundManager.playToggleOn()
                    }
                    .onHover { hovering in
                        setHover("theme-violet", hovering)
                    }

                    ThemeChip(
                        title: "Surprise",
                        subtitle: "Harmonious colours rolled each break",
                        colors: [
                            Color(red: 0.94, green: 0.31, blue: 0.61),
                            Color(red: 0.28, green: 0.76, blue: 0.84),
                            Color(red: 0.56, green: 0.34, blue: 0.98)
                        ],
                        isSelected: visualTheme == "random",
                        isHovered: hoveredElement == "theme-random"
                    ) {
                        visualTheme = "random"
                        soundManager.playToggleOn()
                    }
                    .onHover { hovering in
                        setHover("theme-random", hovering)
                    }
                }
            }
            .padding(UI.cardPadding)
            .frostedCard()
            .padding(.horizontal, UI.sidePadding)

            VStack(spacing: 0) {
                ToggleRow(
                    title: "Messages",
                    subtitle: "A line of words with each break",
                    isOn: showBreakMessage,
                    soundManager: soundManager
                ) { showBreakMessage = $0 }

                rowDivider

                ToggleRow(
                    title: "Ambient",
                    subtitle: "Optional sound bed; mixes with other audio",
                    isOn: musicEnabled,
                    soundManager: soundManager
                ) { musicEnabled = $0 }

                rowDivider

                ToggleRow(
                    title: "SFX",
                    subtitle: "Short chimes and control clicks",
                    isOn: soundEffectsEnabled,
                    soundManager: soundManager
                ) { soundEffectsEnabled = $0 }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, UI.cardPadding)
            .frostedCard(cornerRadius: 20)
            .padding(.horizontal, UI.sidePadding)

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    // MARK: - About Tab Content
    private var aboutFullCanvas: some View {
        VStack(alignment: .leading, spacing: 0) {
            aboutCardsStack

            Spacer(minLength: 14)

            aboutSignature
                .padding(.bottom, 2)
        }
    }

    private var aboutCardsStack: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.spellPink, Color.spellCoral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spellbreak")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundColor(.spellCream.opacity(0.95))

                        Text("Version \(appVersion)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.spellCream.opacity(0.60))
                    }

                    Spacer()
                }
                .padding(.bottom, 2)

                Text("Every break brings a quiet line of its own.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.spellCream.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                Text("It knows the hour, and it knows the moon. Dawn comes in soft, 2am gets knowing, a full moon shows off a little. Skip a few and it notices, gently.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.spellCream.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                Text("Twenty minutes on, twenty seconds off. Or make it a tea timer, a stretch bell, a nudge to look out the window at something far away.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.spellCream.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                Text("No streaks, no red badges, and nothing to feed. Everything stays on this Mac.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.spellCream.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(18)
            .frostedCard()
            .padding(.top, 4)
            .padding(.horizontal, UI.sidePadding)

            VStack(alignment: .leading, spacing: 6) {
                #if APP_STORE
                aboutLink(title: "Privacy Policy", icon: "hand.raised", url: "https://spellbreak.app/privacy")
                aboutLink(title: "Support", icon: "envelope", url: "mailto:pibulus@gmail.com?subject=Spellbreak%20Support")
                #else
                aboutLink(title: "spellbreak.app", icon: "globe", url: "https://spellbreak.app")
                aboutLink(title: "madebypablo.app", icon: "square.grid.2x2", url: "https://madebypablo.app")
                aboutLink(title: "Source on GitHub", icon: "chevron.left.forwardslash.chevron.right", url: "https://github.com/pibulus/spellbreak")
                #endif
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frostedCard()
            .padding(.horizontal, UI.sidePadding)
        }
    }

    private var aboutSignature: some View {
        VStack(spacing: 5) {
            Text("( - ω - ) zzz")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.spellCream.opacity(0.58))

            (
                Text("made by pablo")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.spellCream.opacity(0.80))
                + Text(".")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.spellPink)
            )
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Made by Pablo.")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.2"
    }

    @ViewBuilder
    private func aboutLink(title: String, icon: String, url: String) -> some View {
        let linkKey = "about-\(title)"
        let isHovered = hoveredElement == linkKey
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.spellCoral.opacity(isHovered ? 1.0 : 0.9))
                        .frame(width: 18)
                        .accessibilityHidden(true)

                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.spellCream.opacity(isHovered ? 0.96 : 0.85))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.spellCream.opacity(isHovered ? 0.68 : 0.42))
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHovered ? Color.spellCream.opacity(0.07) : Color.clear)
                )
                .animation(.easeOut(duration: 0.12), value: isHovered)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                setHover(linkKey, hovering)
            }
        }
    }

    private var launchAtLoginSubtitle: String {
        switch launchAtLoginStatus {
        case .enabled:
            return "Starts at login"
        case .requiresApproval:
            return "Pending approval in Login Items"
        case .notFound:
            return "Installable build required"
        case .notRegistered:
            return "Launch at login"
        @unknown default:
            return "Launch at login"
        }
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginStatus = SMAppService.mainApp.status
        launchAtLogin = (launchAtLoginStatus == .enabled)
        launchAtLoginError = nil
    }

    private func handleLaunchAtLoginToggle(_ newValue: Bool) {
        if newValue && launchAtLoginStatus == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
            return
        }
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginStatus = SMAppService.mainApp.status
            launchAtLogin = (launchAtLoginStatus == .enabled)
            if launchAtLoginStatus == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
            }
            launchAtLoginError = nil
        } catch {
            refreshLaunchAtLoginState()
            launchAtLoginError = "Login item status could not change right now."
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .spellInk : .spellCream.opacity(isHovered ? 0.88 : 0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                Color.spellPink,
                                Color.spellPeach
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.spellCream.opacity(isHovered ? 0.14 : 0.08)
                    }
                }
            )
            .clipShape(Capsule())
            .scaleEffect(reduceMotion ? 1.0 : (isHovered && !isSelected ? 1.02 : 1.0))
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Toggle Row
/// Keyboard-focusable full-width row inside a shared card.
struct ToggleRow: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let soundManager: SoundManager
    let onChange: (Bool) -> Void

    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func performToggle() {
        let newValue = !isOn
        onChange(newValue)
        if newValue {
            soundManager.playToggleOn()
        } else {
            soundManager.playToggleOff()
        }
    }

    var body: some View {
        Button(action: performToggle) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.spellCream.opacity(isOn ? 0.95 : 0.78))
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.spellCream.opacity(0.60))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isOn
                                    ? [Color.spellPink, Color.spellCoral]
                                    : [Color.spellCream.opacity(0.16), Color.spellCream.opacity(0.10)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 32)

                    Circle()
                        .fill(Color.spellCream)
                        .frame(width: 24, height: 24)
                        .offset(x: isOn ? 14 : -14)
                        .animation(reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.3, dampingFraction: 0.7), value: isOn)
                }
                .scaleEffect(reduceMotion ? 1.0 : (isHovered ? 1.06 : 1.0))
                .animation(.easeOut(duration: 0.15), value: isHovered)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? Color.spellCream.opacity(0.06) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.spellCoral.opacity(isFocused ? 0.75 : 0), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Gradient Slider
struct GradientSlider: View {
    @Binding var value: Double
    let options: [Double]
    let accessibilityLabel: String
    var accessibilityValueFormatter: (Double) -> String
    var soundManager: SoundManager? = nil
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var lastSoundTime: Date = Date()
    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.spellCream.opacity(0.11))
                    .frame(height: 8)

                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.spellPink,
                                Color.spellPeach
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geometry.size.width * normalizedValue), height: 8)

                // Thumb
                Circle()
                    .fill(Color.spellCream)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.spellCoral.opacity(isFocused ? 0.9 : 0), lineWidth: 2.5)
                    )
                    .scaleEffect(reduceMotion ? 1.0 : (isDragging ? 1.32 : (isHovering || isFocused ? 1.20 : 1.0)))
                    .shadow(color: Color.spellInk.opacity(isDragging ? 0.45 : 0.25),
                            radius: isDragging ? 8 : 4,
                            x: 0, y: 2)
                    .offset(x: geometry.size.width * normalizedValue - 12)
                    .animation(.easeOut(duration: 0.15), value: isDragging)
                    .animation(.easeOut(duration: 0.15), value: isHovering)
                    .onHover { hovering in
                        isHovering = hovering
                    }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .local)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            soundManager?.playSliderGrab()
                        }
                        updateValue(at: drag.location.x, width: geometry.size.width, animated: false)
                    }
                    .onEnded { _ in
                        isDragging = false
                        soundManager?.playSliderRelease()
                    }
            )
            .onTapGesture { location in
                updateValue(at: location.x, width: geometry.size.width, animated: !reduceMotion)
                soundManager?.playSliderGrab()
            }
        }
        .frame(height: 24)
        .focusable(true)
        .focused($isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left, .down:
                adjustValue(.decrement)
            case .right, .up:
                adjustValue(.increment)
            @unknown default:
                break
            }
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValueFormatter(value))
        .accessibilityAdjustableAction { direction in
            adjustValue(direction)
        }
    }

    private func updateValue(at x: CGFloat, width: CGFloat, animated: Bool) {
        guard width > 0, x.isFinite, !options.isEmpty else { return }
        let normalizedPosition = max(0, min(1, x / width))
        let indexFloat = normalizedPosition * Double(max(options.count - 1, 1))
        let nearestIndex = min(max(Int(round(indexFloat)), 0), options.count - 1)
        let newSnappedValue = options[nearestIndex]

        guard newSnappedValue != value else { return }

        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                value = newSnappedValue
            }
        } else {
            value = newSnappedValue
        }

        let now = Date()
        if now.timeIntervalSince(lastSoundTime) > 0.08 {
            soundManager?.playSliderTick()
            lastSoundTime = now
        }
    }

    private func adjustValue(_ direction: AccessibilityAdjustmentDirection) {
        guard !options.isEmpty else { return }
        let currentIndex = options.firstIndex(of: value) ?? closestIndex(to: value)
        let nextIndex: Int

        switch direction {
        case .increment:
            nextIndex = min(currentIndex + 1, options.count - 1)
        case .decrement:
            nextIndex = max(currentIndex - 1, 0)
        @unknown default:
            return
        }

        guard options[nextIndex] != value else { return }

        if reduceMotion {
            value = options[nextIndex]
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                value = options[nextIndex]
            }
        }
        soundManager?.playSliderTick()
    }

    private func closestIndex(to target: Double) -> Int {
        options.indices.min { first, second in
            abs(options[first] - target) < abs(options[second] - target)
        } ?? 0
    }

    private var normalizedValue: Double {
        guard options.count > 1 else { return 0 }
        let index = options.firstIndex(of: value) ?? closestIndex(to: value)
        return Double(index) / Double(options.count - 1)
    }
}

// MARK: - Theme Chip
/// Compact 4-across theme picker card: color dots + name, gradient ring when selected.
struct ThemeChip: View {
    let title: String
    let subtitle: String
    let colors: [Color]
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                HStack(spacing: -8) {
                    ForEach(0..<colors.count, id: \.self) { i in
                        Circle()
                            .fill(colors[i])
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(Color.spellInk.opacity(0.28), lineWidth: 1)
                            )
                            .zIndex(Double(colors.count - i))
                    }
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.spellCream.opacity(isSelected ? 0.95 : 0.78))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.spellCream.opacity(isSelected ? 0.12 : (isHovered ? 0.08 : 0.04)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: isSelected ? colors : [Color.spellCream.opacity(0.11)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(reduceMotion ? 1.0 : (isHovered && !isSelected ? 1.02 : 1.0))
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(subtitle)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) theme")
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: "Select") { action() }
    }
}

// MARK: - Preview
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
