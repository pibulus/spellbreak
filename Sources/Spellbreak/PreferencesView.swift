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

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(fillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
    // MARK: - UI Constants
    private enum UI {
        static let sidePadding: CGFloat = 32
        static let windowPaddingTop: CGFloat = 8          // Sits cleanly below the hidden-title traffic lights
        static let windowPaddingBottom: CGFloat = 26      // Generous bottom air beneath Test Break & signature
        static let sectionSpacing: CGFloat = 16           // Calm rhythm between sections
        static let tabBodyHeight: CGFloat = 418           // Shared 3-toggle height for Time & Vibes
        static let buttonSpacing: CGFloat = 18            // Gap above Test Break
        static let buttonHeight: CGFloat = 46             // Slimmed to match the 48pt top tab pills
        static let cardPadding: CGFloat = 16              // Unified card internal padding
    }
    
    // MARK: - Core Settings
    @AppStorage("breakIntervalMin") private var breakIntervalMin: Double = 20
    @AppStorage("breakDurationSec") private var breakDurationSec: Double = 20
    @AppStorage("lockMode") private var lockMode: Bool = false
    @AppStorage("deferDuringFullscreen") private var deferDuringFullscreen: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
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
    @State private var launchAtLoginStatus: SMAppService.Status = SMAppService.mainApp.status
    @State private var launchAtLoginError: String?
    @EnvironmentObject var soundManager: SoundManager
    @EnvironmentObject var store: Store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: UI.sectionSpacing) {
                // Signature header — owns the top-left beneath the hidden-title traffic lights
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
                        hoveredElement = hovering ? "timer-tab" : nil
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
                        hoveredElement = hovering ? "vibes-tab" : nil
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
                        hoveredElement = hovering ? "about-tab" : nil
                    }
                }
                .padding(.horizontal, UI.sidePadding)
                
                // Lower canvas: Time & Vibes share tabBodyHeight + Test Break;
                // About spans the exact same total height so the cat signature floats centered.
                if selectedTab == 2 && !needsUnlock {
                    aboutFullCanvas
                        .frame(height: UI.tabBodyHeight + UI.buttonSpacing + UI.buttonHeight, alignment: .top)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        ZStack {
                            if selectedTab == 0 {
                                timerContent
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .transition(.opacity)
                            } else if selectedTab == 1 {
                                vibesContent
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .transition(.opacity)
                            } else {
                                aboutCardsOnly
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .transition(.opacity)
                            }
                        }
                        .frame(height: UI.tabBodyHeight, alignment: .top)

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
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .padding(.top, UI.windowPaddingTop)
        .padding(.bottom, UI.windowPaddingBottom)
        .frame(width: 560)
        .background(
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.14, blue: 0.22),
                        Color(red: 0.12, green: 0.10, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle noise texture overlay
                Color.white.opacity(0.02)
                    .background(.ultraThinMaterial)
                    .opacity(0.3)
            }
        )
        .onAppear {
            refreshLaunchAtLoginState()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLaunchAtLoginState()
        }
    }
    
    // MARK: - Test Break & Unlock
    private var testBreakButton: some View {
        Button(action: {
            testButtonPressed = true
            soundManager.playButtonPress()
            NotificationCenter.default.post(name: NSNotification.Name("ShowTestBreak"), object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                testButtonPressed = false
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Test Break")
                    .font(.system(size: 16.5, weight: .bold))
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
            .scaleEffect(testButtonPressed ? 0.98 : (hoveredElement == "test-button" ? 1.01 : 1.0))
            .shadow(color: .black.opacity(hoveredElement == "test-button" ? 0.3 : 0.15),
                    radius: hoveredElement == "test-button" ? 12 : 8,
                    x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredElement = hovering ? "test-button" : nil
        }
    }

    /// Paying (and website) users never see any of this: the row is just Test Break
    private var needsUnlock: Bool {
        switch store.currentAccess {
        case .notStarted, .trial, .trialEnded: return true
        case .checking, .unlocked: return false
        }
    }

    /// Start the free week, or unlock once it's running or done. The price always
    /// comes from StoreKit, localized per storefront, never from a constant.
    private var unlockButton: some View {
        let startingTrial = store.currentAccess == .notStarted
        let title: String
        if startingTrial {
            title = "Try Free for 7 Days"
        } else if let price = store.unlockProduct?.displayPrice {
            title = "Unlock · \(price)"
        } else {
            title = "Unlock"
        }
        // The trial can't start until the unlock price is showing too: App Review
        // wants the downstream charge stated before the trial begins (3.1.1)
        let unavailable = store.isWorking
            || store.unlockProduct == nil
            || (startingTrial && store.trialProduct == nil)

        return Button {
            soundManager.playButtonPress()
            Task {
                if startingTrial {
                    await store.startTrial()
                } else {
                    await store.unlock()
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: startingTrial ? "sparkles" : "lock.open.fill")
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(.spellCream)
            .frame(maxWidth: .infinity)
            .frame(height: UI.buttonHeight)
            .background(Capsule().fill(Color.white.opacity(hoveredElement == "unlock-button" ? 0.14 : 0.08)))
            .overlay(
                Capsule().stroke(
                    LinearGradient(colors: [Color.spellPink, Color.spellPeach], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 2
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(unavailable)
        .opacity(unavailable ? 0.5 : 1)
        .onHover { hovering in
            hoveredElement = hovering ? "unlock-button" : nil
        }
    }

    private var unlockCaption: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(unlockCaptionText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.spellCream.opacity(0.6))
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
                    HStack {
                        Text("Every")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.spellCream.opacity(0.9))
                        Spacer()
                        Text("\(Int(breakIntervalMin))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
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
                            .foregroundColor(.spellCream.opacity(0.7))
                    }
                    
                    GradientSlider(
                        value: $breakIntervalMin,
                        options: [15, 20, 25, 30, 45, 60, 90, 120, 180],
                        accessibilityLabel: "Break interval",
                        accessibilityValueFormatter: { "\(Int($0)) minutes" },
                        soundManager: soundManager
                    )
                }
                
                // Break duration
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("For")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.spellCream.opacity(0.9))
                        Spacer()
                        Text("\(Int(breakDurationSec))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
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
                            .foregroundColor(.spellCream.opacity(0.7))
                    }
                    
                    GradientSlider(
                        value: $breakDurationSec,
                        options: [10, 15, 20, 30, 60, 90, 120, 180],
                        accessibilityLabel: "Break duration",
                        accessibilityValueFormatter: { "\(Int($0)) seconds" },
                        soundManager: soundManager
                    )
                }
            }
            .padding(UI.cardPadding)
            .frostedCard(fillOpacity: hoveredElement == "timing-card" ? 0.10 : 0.06)
            .scaleEffect(hoveredElement == "timing-card" ? 1.01 : 1.0)
            .animation(.easeOut(duration: 0.2), value: hoveredElement)
            .onHover { hovering in
                hoveredElement = hovering ? "timing-card" : nil
            }
            .padding(.horizontal, UI.sidePadding)
            
            // Rule-of-three behaviour card: Lock mode, Pause while busy, Autostart.
            // The 15-second corner countdown pill is baked in so nobody gets jump-scared.
            VStack(spacing: 0) {
                ToggleRow(
                    title: "Lock mode",
                    subtitle: "Hide the hold-to-skip control",
                    isOn: lockMode,
                    soundManager: soundManager
                ) { lockMode = $0 }

                rowDivider

                // Covers the mic too (ScreenBusy.isMicrophoneInUse), so it can't be named
                // for fullscreen alone — switching it off stops both.
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
                    .padding(.horizontal, UI.sidePadding + 4)
            }
            
            Spacer()  // Push content to top within fixed height
        }
        .padding(.top, 4)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(Color.white.opacity(0.06))
    }
    
    // MARK: - Vibes Tab Content
    private var vibesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Visual theme selector — the main event, so it leads
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
                        hoveredElement = hovering ? "theme-aurora" : nil
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
                        hoveredElement = hovering ? "theme-ember" : nil
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
                        hoveredElement = hovering ? "theme-violet" : nil
                    }

                    // Rolls a fresh analogous jewel-tone harmony on every break.
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
                        hoveredElement = hovering ? "theme-random" : nil
                    }
                }
            }
            .padding(UI.cardPadding)
            .frostedCard()
            .padding(.horizontal, UI.sidePadding)

            // Unified 3-row toggle card — matches Time's 3-row symmetry cleanly.
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

            Spacer()  // Push content to top within fixed height
        }
        .padding(.top, 4)
    }

    // MARK: - About Tab Content
    private var aboutFullCanvas: some View {
        VStack(alignment: .leading, spacing: 0) {
            aboutCardsStack

            Spacer(minLength: 16)

            aboutSignature
                .padding(.bottom, 2)
        }
    }

    private var aboutCardsOnly: some View {
        VStack(alignment: .leading, spacing: 0) {
            aboutCardsStack
            Spacer(minLength: 0)
        }
    }

    private var aboutCardsStack: some View {
        VStack(alignment: .leading, spacing: 16) {
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

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spellbreak")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundColor(.spellCream.opacity(0.95))

                        Text("Version \(appVersion)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.spellCream.opacity(0.5))
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
                    .foregroundColor(.spellCream.opacity(0.76))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)

                Text("Twenty minutes on, twenty seconds off. Or make it a tea timer, a stretch bell, a nudge to look out the window at something far away.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.spellCream.opacity(0.76))
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
                aboutLink(title: "spellbreak.app", icon: "globe", url: "https://spellbreak.app")
                aboutLink(title: "madebypablo.app", icon: "square.grid.2x2", url: "https://madebypablo.app")
                aboutLink(title: "Source on GitHub", icon: "chevron.left.forwardslash.chevron.right", url: "https://github.com/pibulus/spellbreak")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frostedCard()
            .padding(.horizontal, UI.sidePadding)
        }
    }

    private var aboutSignature: some View {
        VStack(spacing: 6) {
            Text("( - ω - ) zzz")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.spellCream.opacity(0.56))

            (
                Text("made by pablo")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.spellCream.opacity(0.78))
                + Text(".")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.spellPink)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.1"
        return short
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

                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(.spellCream.opacity(isHovered ? 0.96 : 0.85))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.spellCream.opacity(isHovered ? 0.65 : 0.35))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredElement = hovering ? linkKey : (hoveredElement == linkKey ? nil : hoveredElement)
            }
        }
    }

    private var launchAtLoginSubtitle: String {
        switch launchAtLoginStatus {
        case .enabled:
            return "Starts at login"
        case .requiresApproval:
            return "Approve in Login Items"
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
        launchAtLogin = launchAtLoginStatus == .enabled || launchAtLoginStatus == .requiresApproval
        launchAtLoginError = nil
    }

    private func handleLaunchAtLoginToggle(_ newValue: Bool) {
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginStatus = SMAppService.mainApp.status
            launchAtLogin = launchAtLoginStatus == .enabled || launchAtLoginStatus == .requiresApproval
            launchAtLoginError = nil
        } catch {
            refreshLaunchAtLoginState()
            launchAtLoginError = "macOS wouldn’t change login-item status just now."
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(isSelected ? .spellInk : .spellCream.opacity(0.7))
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
                        Color.white.opacity(isHovered ? 0.14 : 0.08)
                    }
                }
            )
            .cornerRadius(24)
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Toggle Row
/// A single full-width row inside a shared card. No card chrome of its own —
/// that's the parent's job — so several of these can stack into one calm list
/// with dividers between them.
struct ToggleRow: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let soundManager: SoundManager
    let onChange: (Bool) -> Void

    @State private var isHovered = false

    private var toggleAction: () -> Void {
        {
            let newValue = !isOn
            onChange(newValue)
            if newValue {
                soundManager.playToggleOn()
            } else {
                soundManager.playToggleOff()
            }
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.spellCream.opacity(isOn ? 0.95 : 0.75))
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.spellCream.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isOn
                                ? [Color.spellPink, Color.spellCoral]
                                : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 32)

                Circle()
                    .fill(Color.spellCream)
                    .frame(width: 24, height: 24)
                    .offset(x: isOn ? 14 : -14)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
            }
            .scaleEffect(isHovered ? 1.08 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
        )
        .onTapGesture(perform: toggleAction)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On, \(subtitle)" : "Off, \(subtitle)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text(isOn ? "Turn Off" : "Turn On"), toggleAction)
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
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
                    .frame(width: geometry.size.width * normalizedValue, height: 8)
                
                // Thumb
                Circle()
                    .fill(Color.spellCream)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isDragging ? 1.35 : (isHovering ? 1.25 : 1.0))
                    .shadow(color: .black.opacity(isDragging ? 0.4 : 0.2), 
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
                updateValue(at: location.x, width: geometry.size.width, animated: true)
                soundManager?.playSliderGrab()
            }
        }
        .frame(height: 24)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValueFormatter(value))
        .accessibilityAdjustableAction { direction in
            adjustValue(direction)
        }
    }

    private func updateValue(at x: CGFloat, width: CGFloat, animated: Bool) {
        // width can be 0 for a frame during layout; x/width would be NaN and Int(round(.nan)) traps
        guard width > 0, x.isFinite else { return }
        let normalizedPosition = max(0, min(1, x / width))
        let indexFloat = normalizedPosition * Double(options.count - 1)
        let nearestIndex = Int(round(indexFloat))
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

        withAnimation(.easeOut(duration: 0.2)) {
            value = options[nextIndex]
        }
        soundManager?.playSliderTick()
    }

    private func closestIndex(to target: Double) -> Int {
        options.indices.min { first, second in
            abs(options[first] - target) < abs(options[second] - target)
        } ?? 0
    }
    
    private var normalizedValue: Double {
        guard let index = options.firstIndex(of: value) else {
            // If value not in options, find closest and return its normalized position
            return Double(closestIndex(to: value)) / Double(options.count - 1)
        }
        return Double(index) / Double(options.count - 1)
    }
}

// MARK: - Theme Chip
/// Compact 3-across theme picker card: color dots + name, gradient ring when selected.
struct ThemeChip: View {
    let title: String
    /// Not rendered as visible text — it is the hover tooltip and the VoiceOver
    /// hint, which is the only description a screen-reader user ever gets for a
    /// chip whose whole meaning is otherwise three coloured circles.
    let subtitle: String
    let colors: [Color]
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void

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
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .zIndex(Double(colors.count - i))
                    }
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.spellCream.opacity(isSelected ? 0.95 : 0.75))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.12 : (isHovered ? 0.08 : 0.04)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: isSelected ? colors : [Color.white.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(subtitle)
        .accessibilityElement(children: .combine)
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
