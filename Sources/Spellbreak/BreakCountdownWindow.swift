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
        let size = NSSize(width: 260, height: 64)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 12
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
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            Text("\(secondsLeft)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.spellPink, Color.spellPeach],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(minWidth: 26)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Break starts in \(secondsLeft) seconds")
    }
}
