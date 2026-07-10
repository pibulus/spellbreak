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
/// Small click-through panel pinned top-center of the main screen.
final class BreakCountdownWindowController: NSWindowController {
    init(appState: AppState) {
        // Oversized relative to the capsule so its glow never clips
        let size = NSSize(width: 320, height: 92)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 8
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
        HStack(spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.spellPink, Color.spellCoral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(pulse ? 1.12 : 1.0)

            Text("Spell breaks in")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.white.opacity(0.9))

            Text("\(secondsLeft)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
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
                .frame(minWidth: 28)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(
            Capsule()
                .fill(Color(red: 0.04, green: 0.04, blue: 0.05).opacity(0.78))
                .overlay(
                    Capsule().stroke(
                        LinearGradient(
                            colors: [Color.spellPink.opacity(0.5), Color.spellCoral.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                )
        )
        .shadow(color: Color.spellPink.opacity(pulse ? 0.4 : 0.25), radius: 18, y: 2)
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
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
