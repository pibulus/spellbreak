import SwiftUI

struct HeartEyesIcon: View {
    @EnvironmentObject var appState: AppState
    @State private var isPulsing = false
    
    var body: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(appState.timerRunning ? .primary : .secondary)
            .scaleEffect(isPulsing && appState.timerRunning ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
