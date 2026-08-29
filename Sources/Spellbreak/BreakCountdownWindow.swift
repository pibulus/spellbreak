//
//  BreakCountdownWindow.swift
//  Spellbreak
//
//  Floating heads-up pill that counts down the final seconds before a
//  break so the overlay never catches anyone mid-thought.
//

import SwiftUI
import AppKit

// MARK: - Countdown Window Controller
/// Small click-through panel pinned comfortably top-center of the main screen.
final class BreakCountdownWindowController: NSWindowController {
    init(appState: AppState) {
        // Generous bounds so its soft glow never clips
        let size = NSSize(width: 360, height: 104)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 24
        )
        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true  // pure indicator — never eats a click
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: BreakCountdownView().environmentObject(appState))

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Countdown View
struct BreakCountdownView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var appeared = false

    private var secondsLeft: Int {
        max(0, Int(appState.timeRemaining.rounded(.up)))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.spellPink, Color.spellCoral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(pulse ? 1.15 : 1.0)

            Text("Spell breaks in")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(Color.spellCream.opacity(0.95))

            Text("\(secondsLeft)s")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: secondsLeft)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.spellPink, Color.spellPeach],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(minWidth: 36)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .background(
            Capsule()
                .fill(Color(red: 0.078, green: 0.062, blue: 0.058).opacity(0.92))
                .overlay(
                    Capsule().stroke(
                        LinearGradient(
                            colors: [Color.spellPink.opacity(0.65), Color.spellCoral.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                )
        )
        .shadow(color: Color.spellPink.opacity(pulse ? 0.45 : 0.25), radius: 20, y: 3)
        .shadow(color: .black.opacity(0.45), radius: 12, y: 5)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : -14)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.96)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.25 : 0.6)) {
                appeared = true
            }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Break starts in \(secondsLeft) seconds")
    }
}
