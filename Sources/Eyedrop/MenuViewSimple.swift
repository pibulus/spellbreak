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
    @State private var isVisible = false
    @AppStorage("breakIntervalMin") private var breakInterval: Double = 20
    @AppStorage("fancyMenu") private var fancyMenu: Bool = true
    
    var body: some View {
        Group {
            if fancyMenu {
                fancyMenuView
            } else {
                plainMenuView
            }
        }
    }
    
    // MARK: - Fancy Menu (Current)
    private var fancyMenuView: some View {
        VStack(spacing: 0) {
            // Spellbreak branding - mystical vibes
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.6, green: 0.4, blue: 0.9), 
                                        Color(red: 0.8, green: 0.3, blue: 0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Spellbreak")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.7, green: 0.4, blue: 0.9), 
                                        Color(red: 0.9, green: 0.3, blue: 0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .fixedSize()
                }
                Text("Break the spell")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            
            // Timer display with subtle styling
            if appState.timerRunning {
                VStack(spacing: 4) {
                    Text(formatTime(appState.timeRemaining))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("until break")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(10)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            VStack(spacing: 2) {
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
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: 220)
        .background(.ultraThickMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
    
    // MARK: - Plain Menu (macOS Standard)
    private var plainMenuView: some View {
        VStack(spacing: 0) {
            // Simple timer display
            if appState.timerRunning {
                Text(formatTime(appState.timeRemaining))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                
                Divider()
            }
            
            VStack(spacing: 0) {
                PlainMenuItem(title: "Break", action: appState.triggerBreak)
                PlainMenuItem(title: appState.timerRunning ? "Pause" : "Resume") {
                    if appState.timerRunning {
                        appState.stopTimer()
                    } else {
                        appState.startTimer()
                    }
                }
                
                Divider()
                
                PlainMenuItem(title: "Settings", action: appState.showPreferences)
                
                Divider()
                
                PlainMenuItem(title: "Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .background(.regularMaterial)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plain Menu Item
struct PlainMenuItem: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(isHovered ? Color.accentColor : Color.clear)
                .foregroundColor(isHovered ? .white : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}