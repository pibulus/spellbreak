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
/// Small click-through panel pinned comfortably top-center of the active screen.
final class BreakCountdownWindowController: NSWindowController {
    private static let pillSize = NSSize(width: 372, height: 104)

    private static func targetOrigin() -> NSPoint {
        let mouseLoc = NSEvent.mouseLocation
        let screenWithMouse = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
        let screen = screenWithMouse ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        return NSPoint(
            x: screenFrame.midX - pillSize.width / 2,
            y: screenFrame.maxY - pillSize.height - 24
        )
    }

    init(appState: AppState) {
        // Generous bounds so its soft glow never clips
        let origin = Self.targetOrigin()
        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: Self.pillSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true  // pure indicator — never eats a click
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: BreakCountdownView().environmentObject(appState))
        window.contentView?.setAccessibilityElement(false)

        super.init(window: window)
    }

    /// Follow the pointer if the user moves to another physical display mid-countdown.
    func updateScreenPositionIfNeeded() {
        guard let window else { return }
        let desired = Self.targetOrigin()
        if hypot(window.frame.origin.x - desired.x, window.frame.origin.y - desired.y) > 4 {
            window.setFrameOrigin(desired)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Countdown View
struct BreakCountdownView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var pulse = false
    @State private var appeared = false

    private var secondsLeft: Int {
        guard appState.timeRemaining.isFinite else { return 0 }
        return max(0, Int(appState.timeRemaining.rounded(.up)))
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 11) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.spellPink, Color.spellCoral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(pulse ? 1.14 : 1.0)
                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + 5 }
                .accessibilityHidden(true)

            Text("Spell breaks in")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(Color.spellCream.opacity(0.95))

            Text("\(secondsLeft)s")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: secondsLeft)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.spellPink, Color.spellPeach],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(minWidth: 46, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color(red: 0.078, green: 0.062, blue: 0.058).opacity(reduceTransparency ? 1.0 : 0.93))
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
        .shadow(color: Color.spellPink.opacity(pulse ? 0.42 : 0.24), radius: 18, y: 3)
        .shadow(color: Color.spellInk.opacity(0.65), radius: 12, y: 5)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : -14)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.96)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.55)) {
                appeared = true
            }
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityHidden(true)
    }
}
