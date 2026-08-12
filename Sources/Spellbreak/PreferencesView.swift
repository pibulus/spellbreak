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
        static let windowPaddingY: CGFloat = 28          // More breathing room top/bottom
        static let sectionSpacing: CGFloat = 16           // Tighter between sections  
        static let buttonSpacing: CGFloat = 18            // Reasonable gap for CTA button
        static let cardPadding: CGFloat = 16              // Unified card internal padding
    }
    
    // MARK: - Core Settings
    @AppStorage("breakIntervalMin") private var breakIntervalMin: Double = 20
    @AppStorage("breakDurationSec") private var breakDurationSec: Double = 20
    @AppStorage("lockMode") private var lockMode: Bool = false
    @AppStorage("breakWarningEnabled") private var breakWarningEnabled: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("fancyMenu") private var fancyMenu: Bool = true
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"
    @AppStorage("musicEnabled") private var musicEnabled: Bool = false
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled: Bool = true
    @AppStorage("soundVolume") private var soundVolume: Double = 0.5
    
    // MARK: - UI State
    @State private var selectedTab = 0
    @State private var hoveredElement: String? = nil
    @State private var testButtonPressed = false
    @State private var titleOffset: CGFloat = 0
    @State private var sparkleRotation: Double = 0
    @State private var launchAtLoginStatus: SMAppService.Status = SMAppService.mainApp.status
    @State private var launchAtLoginError: String?
    @EnvironmentObject var soundManager: SoundManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: UI.sectionSpacing) {
            // Header with app title
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: titleOffset)
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            titleOffset = -3
                        }
                    }
                
                Spacer()
            }
            .padding(.horizontal, UI.sidePadding)
            
            // Tab selector with gradient
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
            }
            .padding(.horizontal, UI.sidePadding)
            
            // Content area with consistent height
            ZStack {
                if selectedTab == 0 {
                    timerContent
                        .frame(maxWidth: .infinity, alignment: .top)
                        .transition(.opacity)
                } else {
                    vibesContent
                        .frame(maxWidth: .infinity, alignment: .top)
                        .transition(.opacity)
                }
            }
            .frame(height: 480, alignment: .top)  // Top-aligned: overflow can only grow down, never over the tabs
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            
            // Test break button
            Button(action: {
                testButtonPressed = true
                soundManager.playButtonPress()
                NotificationCenter.default.post(name: NSNotification.Name("ShowTestBreak"), object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    testButtonPressed = false
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("Test Break")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.black.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
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
            .padding(.top, UI.buttonSpacing)
            .padding(.horizontal, UI.sidePadding)
        }
        .padding(.top, UI.windowPaddingY)
        .padding(.bottom, UI.windowPaddingY)
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
    
    // MARK: - Timer Tab Content  
    private var timerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Color.clear.frame(height: 4)  // Breathing room below tabs

            // Main timing card
            VStack(spacing: 32) {
                // Break interval
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Every")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
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
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    GradientSlider(
                        value: $breakIntervalMin,
                        options: [15, 30, 60, 90, 120, 180],
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
                            .foregroundColor(.white.opacity(0.9))
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
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    GradientSlider(
                        value: $breakDurationSec,
                        options: [15, 30, 60, 90, 120, 180],
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
            
            // Toggle cards
            HStack(spacing: 16) {
                ToggleCard(
                    title: "Unskippable",
                    subtitle: lockMode ? "No skips!" : "Hold to skip",
                    isOn: lockMode,
                    isHovered: hoveredElement == "skip-toggle",
                    onChange: { lockMode = $0 },
                    soundManager: soundManager
                )
                .onHover { hovering in
                    hoveredElement = hovering ? "skip-toggle" : nil
                }

                ToggleCard(
                    title: "Heads-Up",
                    subtitle: breakWarningEnabled ? "Countdown before the spell lands" : "Straight into the spell",
                    isOn: breakWarningEnabled,
                    isHovered: hoveredElement == "warning-toggle",
                    onChange: { breakWarningEnabled = $0 },
                    soundManager: soundManager
                )
                .onHover { hovering in
                    hoveredElement = hovering ? "warning-toggle" : nil
                }
            }
            .padding(.horizontal, UI.sidePadding)

            ToggleCard(
                title: "Autostart",
                subtitle: launchAtLoginSubtitle,
                isOn: launchAtLogin,
                isHovered: hoveredElement == "auto-toggle",
                onChange: handleLaunchAtLoginToggle,
                soundManager: soundManager
            )
            .onHover { hovering in
                hoveredElement = hovering ? "auto-toggle" : nil
            }
            .padding(.horizontal, UI.sidePadding)

            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.spellPeach)
                    .padding(.horizontal, UI.sidePadding + 4)
            }
            
            Spacer()  // Push content to top within fixed height
        }
    }
    
    // MARK: - Vibes Tab Content
    private var vibesContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Color.clear.frame(height: 4)  // Breathing room below tabs

            // Visual theme selector — the main event, so it leads
            VStack(alignment: .leading, spacing: 14) {
                Text("Visual Theme")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 4)

                HStack(spacing: 12) {
                    ThemeChip(
                        title: "Aurora",
                        subtitle: "Time-aware flowing waves",
                        colors: [
                            Color.spellPink,
                            Color.spellCoral,
                            Color(red: 0.7, green: 0.4, blue: 0.9)
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
                        title: "Cosmic",
                        subtitle: "Deep space nebula",
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.3),
                            Color(red: 0.4, green: 0.1, blue: 0.8),
                            Color(red: 0.2, green: 0.6, blue: 1.0)
                        ],
                        isSelected: visualTheme == "cosmic",
                        isHovered: hoveredElement == "theme-cosmic"
                    ) {
                        visualTheme = "cosmic"
                        soundManager.playToggleOn()
                    }
                    .onHover { hovering in
                        hoveredElement = hovering ? "theme-cosmic" : nil
                    }

                    ThemeChip(
                        title: "Lava Lamp",
                        subtitle: "Retro morphing blobs",
                        colors: [
                            Color(red: 1.0, green: 0.3, blue: 0.4),
                            Color(red: 1.0, green: 0.1, blue: 0.6),
                            Color(red: 1.0, green: 0.5, blue: 0.2)
                        ],
                        isSelected: visualTheme == "lava",
                        isHovered: hoveredElement == "theme-lava"
                    ) {
                        visualTheme = "lava"
                        soundManager.playToggleOn()
                    }
                    .onHover { hovering in
                        hoveredElement = hovering ? "theme-lava" : nil
                    }
                }
            }
            .padding(UI.cardPadding)
            .frostedCard()
            .padding(.horizontal, UI.sidePadding)

            HStack(spacing: 16) {
                ToggleCard(
                    title: "Ambient",
                    subtitle: musicEnabled ? "Break bed switched on" : "Silence during breaks",
                    isOn: musicEnabled,
                    isHovered: hoveredElement == "music-toggle",
                    onChange: { musicEnabled = $0 },
                    soundManager: soundManager
                )
                .onHover { hovering in
                    hoveredElement = hovering ? "music-toggle" : nil
                }

                ToggleCard(
                    title: "SFX",
                    subtitle: soundEffectsEnabled ? "Clicks and chimes" : "Quiet controls",
                    isOn: soundEffectsEnabled,
                    isHovered: hoveredElement == "sfx-toggle",
                    onChange: { soundEffectsEnabled = $0 },
                    soundManager: soundManager
                )
                .onHover { hovering in
                    hoveredElement = hovering ? "sfx-toggle" : nil
                }
            }
            .padding(.horizontal, UI.sidePadding)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sound Volume")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text("\(Int(soundVolume * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.spellPink,
                                    Color.spellPeach
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                GradientSlider(
                    value: $soundVolume,
                    options: [0, 0.25, 0.5, 0.75, 1.0],
                    accessibilityLabel: "Sound volume",
                    accessibilityValueFormatter: { "\(Int($0 * 100)) percent" },
                    soundManager: soundManager
                )
            }
            .padding(UI.cardPadding)
            .frostedCard()
            .padding(.horizontal, UI.sidePadding)

            // Menu style toggle — menu-bar cosmetics, least-reached-for, so it sits last
            ToggleCard(
                title: "Fancy Menu",
                subtitle: "Mystical vibes vs clean text",
                isOn: fancyMenu,
                isHovered: hoveredElement == "menu-toggle",
                onChange: { fancyMenu = $0 },
                soundManager: soundManager
            )
            .onHover { hovering in
                hoveredElement = hovering ? "menu-toggle" : nil
            }
            .padding(.horizontal, UI.sidePadding)

            Spacer()  // Push content to top within fixed height
        }
    }

    private var launchAtLoginSubtitle: String {
        switch launchAtLoginStatus {
        case .enabled:
            return "Starts when your Mac does"
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
            .foregroundColor(isSelected ? .black : .white.opacity(0.7))
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

// MARK: - Toggle Card
struct ToggleCard: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let isHovered: Bool
    let onChange: (Bool) -> Void
    let soundManager: SoundManager

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

    private var titleColors: [Color] {
        isOn
            ? [Color.spellCoral, Color.spellPink]
            : [.white, .white]
    }

    private var trackColors: [Color] {
        isOn
            ? [Color.spellPink, Color.spellCoral]
            : [Color.white.opacity(0.15), Color.white.opacity(0.1)]
    }

    private var accessibilityState: String {
        isOn ? "On, \(subtitle)" : "Off, \(subtitle)"
    }
    
    var body: some View {
        HStack {
            label
            Spacer()
            switchControl
        }
        .padding(12)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture(perform: toggleAction)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityState)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text(isOn ? "Turn Off" : "Turn On"), toggleAction)
        .frame(maxWidth: .infinity)
        .frostedCard(cornerRadius: 20, fillOpacity: isHovered ? 0.10 : 0.06)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: titleColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var switchControl: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: trackColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 64, height: 36)

            Circle()
                .fill(.white)
                .frame(width: 28, height: 28)
                .offset(x: isOn ? 15 : -15)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        }
        .scaleEffect(isHovered ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
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
                    .fill(.white)
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
                    .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.75))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
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
