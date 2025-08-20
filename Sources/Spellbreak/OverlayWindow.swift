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
    @EnvironmentObject var appState: AppState
    @StateObject private var soundManager = SoundManager()
    @State private var opacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var textScale: Double = 1.0
    @State private var timeRemaining: Int = 0
    @State private var countdownTimer: Timer?
    @State private var dismissWorkItem: DispatchWorkItem?
    @State private var isHoldingToSkip = false
    @State private var holdProgress: Double = 0
    @State private var holdTimer: Timer?
    @State private var showSkipRing = false
    @State private var isHoveringRing = false
    @State private var escapePulse: Double = 0
    @State private var breakMessage: String = ""
    @AppStorage("lockMode") private var lockMode: Bool = false
    @AppStorage("breakDurationSec") private var breakDuration: Double = 20
    @AppStorage("musicEnabled") private var musicEnabled: Bool = false
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"
    
    // Calculate required hold duration: 1s per minute, clamped 2-15s
    private var requiredHoldDuration: Double {
        let duration = breakDuration / 60.0
        return min(max(duration, 2.0), 15.0)
    }
    
    var body: some View {
        ZStack {
            // Desktop blur with thick material for frosted glass
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()
            
            // Theme-based animated background
            Group {
                switch visualTheme {
                case "lava":
                    LavaLampBackground()
                        .blur(radius: 25)
                        .opacity(0.85)
                case "cosmic":
                    CosmicBackground()
                        .blur(radius: 20)
                        .opacity(0.9)
                default: // "aurora"
                    AuroraBackground()
                        .blur(radius: 30)
                        .opacity(0.8)
                }
            }
            
            // Dark tint for contrast + escape pulse effect
            Rectangle()
                .fill(.black.opacity(0.2 + escapePulse * 0.1))
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.8), value: escapePulse)
            
            // Ambient floating particles on top
            AmbientParticles()
                .opacity(0.7)
            
            // Centered message - properly centered vertically
            VStack(spacing: 0) {
                Spacer()
                
                // Main message with soft glow (no blur on text itself)
                Text(breakMessage)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    // Soft white glow
                    .shadow(color: .white.opacity(0.5), radius: 20)
                    .shadow(color: .white.opacity(0.3), radius: 40)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    .opacity(messageOpacity)
                    .scaleEffect(textScale)
                    .padding(.horizontal, 60)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .offset(y: lockMode ? 0 : -30)  // Offset up slightly when skip ring is shown
                
                Spacer()
                
                // Hold-to-skip ring at bottom
                if !lockMode {
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(Color.white.opacity(isHoveringRing ? 0.25 : 0.15), lineWidth: 3)
                            .frame(width: 64, height: 64)
                        
                        // Progress ring
                        Circle()
                            .trim(from: 0, to: holdProgress)
                            .stroke(
                                Color.white.opacity(0.8),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.05), value: holdProgress)
                        
                        // Center content
                        if isHoldingToSkip && holdProgress > 0 {
                            // Show progress when holding
                            Text("\(Int(holdProgress * 100))")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            // Show "skip" text when idle
                            Text("skip")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(isHoveringRing ? 0.7 : 0.4))
                                .animation(.easeInOut(duration: 0.2), value: isHoveringRing)
                        }
                    }
                    .scaleEffect(isHoldingToSkip ? 1.15 : (isHoveringRing ? 1.05 : 1.0))
                    .animation(.spring(duration: 0.3, bounce: 0.3), value: isHoldingToSkip)
                    .animation(.easeOut(duration: 0.2), value: isHoveringRing)
                    .opacity(showSkipRing ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: showSkipRing)
                    .onHover { hovering in
                        isHoveringRing = hovering
                    }
                    .padding(.bottom, 60)
                }
            }
            
            // Timer in bottom right - aligned with skip ring
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if timeRemaining > 0 {
                        Text(formatTimeShort(timeRemaining))
                            .font(.system(size: 26, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .opacity(messageOpacity * 0.8)
                            .padding(.trailing, 50)
                            .padding(.bottom, 68)  // Aligned with skip ring (60 + 8 for visual balance)
                    }
                }
            }
        }
        .opacity(opacity)
        .onLongPressGesture(minimumDuration: requiredHoldDuration, maximumDistance: .infinity) {
            // Long press completed
            if showSkipRing && !lockMode {
                skipBreak()
            }
        } onPressingChanged: { pressing in
            if showSkipRing && !lockMode {
                isHoldingToSkip = pressing
                if pressing {
                    startHoldTimer()
                } else {
                    holdTimer?.invalidate()
                    if holdProgress < 1.0 {
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                            holdProgress = 0
                        }
                    }
                }
            }
        }
        .onAppear {
            // Generate contextual break message
            let context = appState.getBreakContext()
            breakMessage = SpellTextGenerator.generateMessage(
                breakCount: context.breakCount,
                skippedCount: context.skippedCount,
                lastBreakInterval: context.lastBreakInterval
            )
            
            // Play break start chime
            soundManager.playBreakStartChime()
            
            // Listen for escape key presses
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("EscapePressed"),
                object: nil,
                queue: .main
            ) { _ in
                // Subtle pulse effect when escape is pressed
                escapePulse = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    escapePulse = 0
                }
            }
            
            // Slower, more gentle fade in
            withAnimation(.easeOut(duration: 1.2)) {
                opacity = 1
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                messageOpacity = 1
            }
            
            // Gentle breathing animation (90bpm feel from old version)
            withAnimation(.easeInOut(duration: 1.334).repeatForever(autoreverses: true).delay(1.5)) {
                textScale = 1.05
            }
            
            // Start ambient sound if enabled
            if musicEnabled {
                soundManager.playAmbient()
            }
            
            // Start countdown
            timeRemaining = Int(breakDuration)
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer.invalidate()
                }
            }
            
            // Show skip ring after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    showSkipRing = true
                }
            }
            
            // Auto dismiss after break duration
            let actualBreakDuration = breakDuration > 0 ? breakDuration : 20
            let work = DispatchWorkItem { [weak appState] in
                guard let appState, appState.showingOverlay else { return }
                appState.markBreakCompleted()
                
                // Smooth fade out
                withAnimation(.easeInOut(duration: 0.8)) {
                    messageOpacity = 0
                }
                
                withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                    opacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    appState.showingOverlay = false
                }
                soundManager.stopAmbient()
            }
            dismissWorkItem?.cancel()
            dismissWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + actualBreakDuration, execute: work)
        }
        .onDisappear {
            countdownTimer?.invalidate()
            dismissWorkItem?.cancel()
            soundManager.stopAmbient()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatTimeShort(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds)"  // Just the number, no "s"
        }
    }
    
    private func skipBreak() {
        // Play skip complete sound
        soundManager.playSkipComplete()
        
        appState.markBreakSkipped()
        
        // Quick but smooth fade out for skip
        withAnimation(.easeOut(duration: 0.4)) {
            messageOpacity = 0
            showSkipRing = false
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            appState.showingOverlay = false
        }
        soundManager.stopAmbient()
        
        // Clean up timers
        holdTimer?.invalidate()
        holdTimer = nil
        countdownTimer?.invalidate()
        dismissWorkItem?.cancel()
    }
    
    private func startHoldTimer() {
        holdProgress = 0
        let updateInterval = 0.05 // 20 FPS updates
        let increments = requiredHoldDuration / updateInterval
        
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            if isHoldingToSkip {
                holdProgress = min(holdProgress + (1.0 / increments), 1.0)
                if holdProgress >= 1.0 {
                    timer.invalidate()
                }
            } else {
                timer.invalidate()
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    holdProgress = 0
                }
            }
        }
    }
}

