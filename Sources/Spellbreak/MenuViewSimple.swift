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
    @AppStorage("breakIntervalMin") private var breakInterval: Double = 20
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
                .onHover { hoveredItem = $0 ? "break" : nil }
                
                // Pause/Resume — one control, and "Resume" really does resume.
                SimpleMenuItem(
                    icon: appState.timerRunning ? "pause.fill" : "play.fill",
                    title: appState.timerRunning ? "Pause" : (appState.timerPaused ? "Resume" : "Start"),
                    isHovered: hoveredItem == "timer"
                ) {
                    onRequestClose()
                    appState.toggleTimer()
                }
                .onHover { hoveredItem = $0 ? "timer" : nil }
                
                Divider()
                    .background(Color.white.opacity(0.08))
                    .padding(.vertical, 4)
                
                // Settings
                SimpleMenuItem(
                    icon: "gearshape",
                    title: "Settings",
                    isHovered: hoveredItem == "settings"
                ) {
                    onRequestClose()
                    appState.showPreferences()
                }
                .onHover { hoveredItem = $0 ? "settings" : nil }
                
                // Quit
                SimpleMenuItem(
                    icon: "xmark",
                    title: "Quit",
                    isHovered: hoveredItem == "quit"
                ) {
                    onRequestClose()
                    NSApplication.shared.terminate(nil)
                }
                .onHover { hoveredItem = $0 ? "quit" : nil }
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
                Color.white.opacity(0.02)
            }
        )
    }

    private var statusSubtext: String {
        if hoveredItem == "status-card" {
            if appState.timerRunning { return "click to pause" }
            return appState.timerPaused ? "click to resume" : "click to start"
        }
        if appState.timerRunning { return "until break" }
        return appState.timerPaused ? "paused" : "no break scheduled"
    }

    private var timerStatusCard: some View {
        let isHovered = hoveredItem == "status-card"
        let isActive = appState.timerRunning || appState.timerPaused

        return Button {
            appState.toggleTimer()
        } label: {
            VStack(spacing: 4) {
                // Paused keeps showing the time it stopped at — that number IS the promise
                // that resuming picks up where it left off.
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
                        .opacity(appState.timerPaused ? 0.55 : 1)
                } else {
                    Text("Off")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundColor(.spellCream.opacity(0.85))
                }

                Text(statusSubtext)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isHovered ? .spellCream.opacity(0.92) : .spellCream.opacity(0.58))
                    .animation(.easeInOut(duration: 0.14), value: isHovered)
            }
            .padding(.vertical, 14)
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
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }
}

// MARK: - Simple Menu Item
struct SimpleMenuItem: View {
    let icon: String
    let title: String
    var accent: Bool = false
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        accent
                            ? LinearGradient(colors: [Color.spellPink, Color.spellCoral], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.spellCream.opacity(isHovered ? 0.85 : 0.55)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: accent ? .semibold : .medium, design: .rounded))
                    .foregroundColor(accent ? .spellCream : Color.spellCream.opacity(isHovered ? 0.96 : 0.82))
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.spellPink.opacity(0.11) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
