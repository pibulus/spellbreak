//
//  MenuViewSimple.swift
//  Spellbreak
//
//  Menu bar interface showing next break time and quick actions.
//

import SwiftUI

// MARK: - Simple Menu View
/// Minimalist dropdown - clean, readable, single words
struct MenuViewSimple: View {
    @EnvironmentObject var appState: AppState
    @State private var hoveredItem: String? = nil
    var onRequestClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            timerStatusCard
                .padding(.top, 10)

            VStack(spacing: 2) {
                // Break Now
                SimpleMenuItem(
                    icon: "moon.stars.fill",
                    title: "Break Now",
                    accent: true,
                    isHovered: hoveredItem == "break"
                ) {
                    onRequestClose()
                    appState.triggerBreak()
                }
                .onHover { hoveredItem = $0 ? "break" : (hoveredItem == "break" ? nil : hoveredItem) }

                // Pause/Resume — one control, and "Resume" really does resume.
                SimpleMenuItem(
                    icon: appState.timerRunning ? "pause.fill" : "play.fill",
                    title: appState.timerRunning ? "Pause" : (appState.timerPaused ? "Resume" : "Start"),
                    isHovered: hoveredItem == "timer"
                ) {
                    onRequestClose()
                    appState.toggleTimer()
                }
                .onHover { hoveredItem = $0 ? "timer" : (hoveredItem == "timer" ? nil : hoveredItem) }

                menuDivider

                // Settings…
                SimpleMenuItem(
                    icon: "gearshape",
                    title: "Settings…",
                    shortcutHint: "⌘,",
                    isHovered: hoveredItem == "settings"
                ) {
                    onRequestClose()
                    appState.showPreferences()
                }
                .onHover { hoveredItem = $0 ? "settings" : (hoveredItem == "settings" ? nil : hoveredItem) }

                menuDivider

                // Quit Spellbreak
                SimpleMenuItem(
                    icon: "xmark",
                    title: "Quit Spellbreak",
                    shortcutHint: "⌘Q",
                    isHovered: hoveredItem == "quit"
                ) {
                    onRequestClose()
                    NSApplication.shared.terminate(nil)
                }
                .onHover { hoveredItem = $0 ? "quit" : (hoveredItem == "quit" ? nil : hoveredItem) }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 9)
        }
        .frame(width: 208)
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.17, green: 0.14, blue: 0.23),
                        Color(red: 0.12, green: 0.10, blue: 0.17)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Color.spellCream.opacity(0.02)
            }
        )
    }

    private var menuDivider: some View {
        Divider()
            .overlay(Color.spellCream.opacity(0.08))
            .padding(.vertical, 4)
    }

    private var statusSubtext: String {
        if hoveredItem == "status-card" {
            if appState.timerRunning { return "click to pause" }
            return appState.timerPaused ? "click to resume" : "click to start"
        }
        if appState.timerRunning { return "until break" }
        return appState.timerPaused ? "paused" : "no break scheduled"
    }

    private var statusAccessibilityValue: String {
        if appState.timerRunning {
            return "\(appState.timeRemaining.spokenDuration) until break"
        } else if appState.timerPaused {
            return "Paused at \(appState.timeRemaining.spokenDuration)"
        } else {
            return "No break scheduled"
        }
    }

    private var timerStatusCard: some View {
        let isHovered = hoveredItem == "status-card"
        let isActive = appState.timerRunning || appState.timerPaused

        return Button {
            appState.toggleTimer()
        } label: {
            VStack(spacing: 4) {
                // Fixed 32pt headline box prevents a 6pt vertical jump between "20:00" and "Off"
                ZStack {
                    if isActive {
                        Text(appState.timeRemaining.mmss)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.spellPink,
                                        Color.spellCoral,
                                        Color(red: 1.0, green: 0.78, blue: 0.44)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(appState.timerPaused ? 0.58 : 1)
                    } else {
                        Text("Off")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.spellCream.opacity(0.85))
                    }
                }
                .frame(height: 32)

                Text(statusSubtext)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isHovered ? .spellCream.opacity(0.92) : .spellCream.opacity(0.60))
                    .animation(.easeInOut(duration: 0.14), value: isHovered)
            }
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color.spellPink.opacity(isHovered ? 0.18 : (appState.timerRunning ? 0.12 : 0.05)),
                        Color.spellPeach.opacity(isHovered ? 0.12 : (appState.timerRunning ? 0.06 : 0.03))
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.spellPink.opacity(isHovered ? 0.42 : (appState.timerRunning ? 0.26 : 0.12)),
                                Color.spellPeach.opacity(isHovered ? 0.30 : (appState.timerRunning ? 0.16 : 0.08))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hoveredItem = $0 ? "status-card" : (hoveredItem == "status-card" ? nil : hoveredItem) }
        .accessibilityLabel(appState.timerRunning ? "Pause timer" : (appState.timerPaused ? "Resume timer" : "Start timer"))
        .accessibilityValue(statusAccessibilityValue)
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }
}

// MARK: - Simple Menu Item
struct SimpleMenuItem: View {
    let icon: String
    let title: String
    var shortcutHint: String? = nil
    var accent: Bool = false
    let isHovered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        accent
                            ? LinearGradient(colors: [Color.spellPink, Color.spellCoral], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.spellCream.opacity(isHovered ? 0.88 : 0.58)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 18)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 13.5, weight: accent ? .semibold : .medium, design: .rounded))
                    .foregroundColor(accent ? .spellCream : Color.spellCream.opacity(isHovered ? 0.96 : 0.84))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let shortcutHint {
                    Text(shortcutHint)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.spellCream.opacity(isHovered ? 0.55 : 0.36))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.spellPink.opacity(0.12) : Color.clear)
            )
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
