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
    @AppStorage("lockMode") private var lockMode: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("fancyMenu") private var fancyMenu: Bool = true
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"
    
    // MARK: - UI State
    @State private var selectedTab = 0
    @State private var hoveredElement: String? = nil
    @State private var testButtonPressed = false
    @State private var titleOffset: CGFloat = 0
    @State private var sparkleRotation: Double = 0
    @StateObject private var soundManager = SoundManager()
    
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
                                Color(red: 0.95, green: 0.4, blue: 0.8),
                                Color(red: 1.0, green: 0.6, blue: 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(sparkleRotation))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                            sparkleRotation = 8
                        }
                    }
                
                Text("Spellbreak")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: titleOffset)
                    .onAppear {
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
            .frame(height: 360)  // Fixed height for consistent window size
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
                            Color(red: 0.95, green: 0.4, blue: 0.8),
                            Color(red: 1.0, green: 0.7, blue: 0.5),
                            Color(red: 1.0, green: 0.8, blue: 0.4)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .scaleEffect(testButtonPressed ? 0.96 : (hoveredElement == "test-button" ? 1.03 : 1.0))
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
        .frame(width: 520)
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
    }
    
    // MARK: - Timer Tab Content  
    private var timerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Color.clear.frame(height: 12)  // Alignment spacer to match Vibes tab
            
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
                                        Color(red: 0.95, green: 0.4, blue: 0.8),
                                        Color(red: 1.0, green: 0.6, blue: 0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("minutes")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    GradientSlider(value: $breakIntervalMin, range: 5...60, step: 5)
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
                    
                    GradientSlider(value: $breakDurationSec, range: 5...60, step: 5)
                }
            }
            .padding(UI.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(hoveredElement == "timing-card" ? 0.10 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(hoveredElement == "timing-card" ? 1.03 : 1.0)
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
                    onChange: { lockMode = $0 }
                )
                .onHover { hovering in
                    hoveredElement = hovering ? "skip-toggle" : nil
                }
                
                ToggleCard(
                    title: "Autostart",
                    subtitle: "Launch at login",
                    isOn: launchAtLogin,
                    isHovered: hoveredElement == "auto-toggle",
                    onChange: { newValue in
                        launchAtLogin = newValue
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update launch at login: \(error)")
                        }
                    }
                )
                .onHover { hovering in
                    hoveredElement = hovering ? "auto-toggle" : nil
                }
            }
            .padding(.horizontal, UI.sidePadding)
            
            Spacer()  // Push content to top within fixed height
        }
    }
    
    // MARK: - Vibes Tab Content
    private var vibesContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Add spacing to match timer tab's card placement
            Color.clear.frame(height: 12)  // Alignment spacer
            
            // Menu style toggle
            ToggleCard(
                title: "Fancy Menu",
                subtitle: "Mystical vibes vs clean text",
                isOn: fancyMenu,
                isHovered: hoveredElement == "menu-toggle",
                onChange: { fancyMenu = $0 }
            )
            .onHover { hovering in
                hoveredElement = hovering ? "menu-toggle" : nil
            }
            .padding(.horizontal, UI.sidePadding)
            
            // Visual theme selector
            VStack(alignment: .leading, spacing: 16) {
                Text("Visual Theme")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 4)
                
                VStack(spacing: 12) {
                    // Aurora theme
                    ThemeOption(
                        title: "Aurora",
                        subtitle: "Time-aware flowing waves",
                        icon: "sparkles",
                        colors: [
                            Color(red: 0.95, green: 0.4, blue: 0.8),
                            Color(red: 1.0, green: 0.6, blue: 0.5),
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
                    
                    // Cosmic theme
                    ThemeOption(
                        title: "Cosmic",
                        subtitle: "Deep space nebula",
                        icon: "moon.stars.fill",
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
                    
                    // Lava Lamp theme
                    ThemeOption(
                        title: "Lava Lamp",
                        subtitle: "Retro morphing blobs",
                        icon: "lava.floor.fill",
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
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, UI.sidePadding)
            
            Spacer()  // Push content to top within fixed height
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
                                Color(red: 0.95, green: 0.4, blue: 0.8),
                                Color(red: 1.0, green: 0.7, blue: 0.5)
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
            .scaleEffect(isHovered && !isSelected ? 1.08 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toggle Card
struct ToggleCard: View {
    let title: String
    let subtitle: String
    let isOn: Bool
    let isHovered: Bool
    let onChange: (Bool) -> Void
    @StateObject private var soundManager = SoundManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            isOn ? 
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.6, blue: 0.5),
                                    Color(red: 0.95, green: 0.4, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : 
                            LinearGradient(
                                colors: [.white, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                
                // Custom gradient toggle
                ZStack {
                    Capsule()
                        .fill(
                            isOn ? 
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.4, blue: 0.8),
                                    Color(red: 1.0, green: 0.6, blue: 0.5)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.1)
                                ],
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
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .animation(.easeOut(duration: 0.15), value: isHovered)
                .onTapGesture {
                    let newValue = !isOn
                    onChange(newValue)
                    // Play sound based on new state
                    if newValue {
                        soundManager.playToggleOn()
                    } else {
                        soundManager.playToggleOff()
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(isHovered ? 0.10 : 0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - Gradient Slider
struct GradientSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
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
                                Color(red: 0.95, green: 0.4, blue: 0.8),
                                Color(red: 1.0, green: 0.7, blue: 0.5)
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
                        if hovering {
                            NSCursor.openHand.push()
                        } else if !isDragging {
                            NSCursor.pop()
                        }
                    }
                    .allowsHitTesting(true)
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .local)
                            .onChanged { drag in
                                if !isDragging {
                                    isDragging = true
                                    NSCursor.closedHand.push()
                                    // Play grab sound on drag start
                                    playSliderSound(volume: 0.3, pitch: 1.2)
                                }
                                let oldValue = value
                                let newValue = (drag.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                let newSnappedValue = round(min(max(newValue, range.lowerBound), range.upperBound) / step) * step
                                
                                // Only play sound and update if we've moved to a new step
                                if newSnappedValue != value {
                                    value = newSnappedValue
                                    // Play a subtle tick for each step change, but throttle to prevent spam
                                    let now = Date()
                                    if now.timeIntervalSince(lastSoundTime) > 0.08 { // Max ~12 sounds per second
                                        playSliderSound(volume: 0.25, pitch: 1.05)
                                        lastSoundTime = now
                                    }
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                                NSCursor.pop()
                                if isHovering {
                                    NSCursor.openHand.push()
                                }
                                // Play release sound
                                playSliderSound(volume: 0.35, pitch: 0.9)
                            }
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                // Allow clicking anywhere on the track to jump to that value
                let newValue = (location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                withAnimation(.easeOut(duration: 0.2)) {
                    value = round(min(max(newValue, range.lowerBound), range.upperBound) / step) * step
                }
                // Play jump sound (grab sound)
                playSliderSound(volume: 0.35, pitch: 1.2)
            }
        }
        .frame(height: 24)
    }
    
    private var normalizedValue: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private func playSliderSound(volume: Float = 0.2, pitch: Float = 1.0) {
        DispatchQueue.global(qos: .userInteractive).async {
            // Determine which sound to play based on pitch
            let soundName: String
            if pitch < 1.0 {
                // Release sound
                soundName = "slider-release"
            } else if pitch > 1.1 {
                // Jump/grab sound  
                soundName = "slider-grab"
            } else {
                // Tick sound for dragging
                soundName = "slider-tick"
            }
            
            // Try to load and play our custom sound
            if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3", subdirectory: "Sounds") {
                if let sound = NSSound(contentsOf: soundURL, byReference: false) {
                    sound.volume = volume
                    sound.play()
                    return
                }
            }
            
            // Fallback: try without subdirectory
            if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
                if let sound = NSSound(contentsOf: soundURL, byReference: false) {
                    sound.volume = volume
                    sound.play()
                    return
                }
            }
            
            // Ultimate fallback for development/testing
            if volume > 0.25 {
                NSSound.beep()
            }
        }
    }
}

// MARK: - Theme Option
struct ThemeOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Color preview circles
                HStack(spacing: -8) {
                    ForEach(0..<colors.count, id: \.self) { i in
                        Circle()
                            .fill(colors[i])
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .zIndex(Double(colors.count - i))
                    }
                }
                .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(isSelected ? 0.95 : 0.8))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(isSelected ? 0.6 : 0.4))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}