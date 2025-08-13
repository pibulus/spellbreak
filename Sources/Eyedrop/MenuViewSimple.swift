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
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer display with subtle styling
            if appState.timerRunning {
                VStack(spacing: 2) {
                    Text(formatTime(appState.timeRemaining))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("until break")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.white.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            VStack(spacing: 1) {
                // Break Now
                SimpleMenuItem(
                    icon: "moon.stars.fill",
                    title: "Break",
                    accent: true,
                    isHovered: hoveredItem == "break"
                ) {
                    appState.triggerBreak()
                }
                .onHover { hoveredItem = $0 ? "break" : nil }
                
                // Pause/Resume
                SimpleMenuItem(
                    icon: appState.timerRunning ? "pause.fill" : "play.fill",
                    title: appState.timerRunning ? "Pause" : "Resume",
                    isHovered: hoveredItem == "timer"
                ) {
                    if appState.timerRunning {
                        appState.stopTimer()
                    } else {
                        appState.startTimer()
                    }
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
                    appState.showPreferences()
                }
                .onHover { hoveredItem = $0 ? "settings" : nil }
                
                // Quit
                SimpleMenuItem(
                    icon: "xmark",
                    title: "Quit",
                    isHovered: hoveredItem == "quit"
                ) {
                    NSApplication.shared.terminate(nil)
                }
                .onHover { hoveredItem = $0 ? "quit" : nil }
            }
            .padding(4)
        }
        .frame(width: 160)
        .background(
            ZStack {
                Color.black.opacity(0.1)
                    .background(.ultraThinMaterial)
            }
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accent ? Color(red: 1.0, green: 0.6, blue: 0.5) : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 14, weight: accent ? .semibold : .medium))
                    .foregroundColor(accent ? .primary : Color.primary.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}