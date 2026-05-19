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
    @EnvironmentObject var soundManager: SoundManager
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
    @State private var escapeObserver: NSObjectProtocol?
    @AppStorage("lockMode") private var lockMode: Bool = true
    @AppStorage("breakDurationSec") private var breakDuration: Double = 20
    @AppStorage("musicEnabled") private var musicEnabled: Bool = false
    @AppStorage("visualTheme") private var visualTheme: String = "aurora"
    
    // Calculate required hold duration from break length, clamped 2-15s.
    private var requiredHoldDuration: Double {
        let duration = actualBreakDuration / 60.0
        return min(max(duration, 2.0), 15.0)
    }

    private var actualBreakDuration: TimeInterval {
        guard breakDuration.isFinite else { return 20 }
        return max(1, breakDuration)
    }

    private var themeGlowColor: Color {
        switch visualTheme {
        case "lava":
            return Color(red: 1.0, green: 0.36, blue: 0.34)
        case "cosmic":
            return Color(red: 0.42, green: 0.68, blue: 1.0)
        default:
            return Color(red: 0.98, green: 0.46, blue: 0.78)
        }
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
                        .blur(radius: 16)
                        .opacity(0.85)
                case "cosmic":
                    CosmicBackground()
                        .blur(radius: 4)
                        .opacity(0.9)
                default: // "aurora"
                    AuroraBackground()
                        .blur(radius: 24)
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
                    .shadow(color: themeGlowColor.opacity(0.45), radius: 34)
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
                    .onLongPressGesture(minimumDuration: requiredHoldDuration, maximumDistance: .infinity) {
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
            escapeObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name("EscapePressed"),
                object: nil,
                queue: .main
            ) { _ in
                // Subtle pulse effect when escape is pressed
                escapePulse = 1
                escapePulseResetWorkItem?.cancel()
                let resetWork = DispatchWorkItem {
                    escapePulse = 0
                }
                escapePulseResetWorkItem = resetWork
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: resetWork)
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
            
            hasResolvedBreak = false
            breakEndsAt = Date().addingTimeInterval(actualBreakDuration)
            updateCountdown()
            startCountdownTimer()
            scheduleSkipRingReveal()
            scheduleAutoCompletion()
        }
        .onDisappear {
            cleanupScheduledWork()
            soundManager.stopAmbient()
            // Remove notification observer
            if let observer = escapeObserver {
                NotificationCenter.default.removeObserver(observer)
                escapeObserver = nil
            }
        }
    }

    private func formatTimeShort(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60)m"
        } else {
            return "\(seconds)"  // Just the number, no "s"
        }
    }

    private func scheduleTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: repeats, block: block)
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = scheduleTimer(withTimeInterval: 0.5, repeats: true) { timer in
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
            guard !hasResolvedBreak else { return }
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
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

            withAnimation(.easeOut(duration: 0.4)) {
                messageOpacity = 0
                showSkipRing = false
            }

            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                opacity = 0
            }

            scheduleOverlayClose(after: 0.7)
        } else {
            appState.markBreakCompleted()

            withAnimation(.easeInOut(duration: 0.8)) {
                messageOpacity = 0
            }

            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                opacity = 0
            }

            scheduleOverlayClose(after: 1.2)
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
        let updateInterval = 0.05 // 20 FPS updates
        let increments = requiredHoldDuration / updateInterval
        
        holdTimer?.invalidate()
        holdTimer = scheduleTimer(withTimeInterval: updateInterval, repeats: true) { timer in
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
