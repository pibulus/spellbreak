import SwiftUI
import AppKit

// MARK: - Hold to Skip Ring
/// Circular progress ring that fills as user holds to skip the break
struct HoldToSkipRing: View {
    @Binding var isHolding: Bool
    @Binding var holdProgress: Double
    let requiredHoldDuration: Double
    let soundManager: SoundManager
    let onComplete: () -> Void
    
    @State private var ringScale: Double = 1.0
    @State private var pulseOpacity: Double = 0.0
    
    private let ringSize: CGFloat = 120
    private let strokeWidth: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Pulse effect when holding
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.4).opacity(0.3),
                            Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: strokeWidth * 2
                )
                .frame(width: ringSize * 1.2, height: ringSize * 1.2)
                .scaleEffect(ringScale)
                .opacity(pulseOpacity)
                .blur(radius: 8)
            
            // Background ring
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: strokeWidth
                )
                .frame(width: ringSize, height: ringSize)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.4),
                            Color(red: 1.0, green: 0.4, blue: 0.6),
                            Color(red: 0.8, green: 0.3, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear(duration: 0.1), value: holdProgress)
            
            // Center content
            VStack(spacing: 4) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.9))
                    .scaleEffect(isHolding ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHolding)
                
                Text("Hold to Skip")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                if isHolding && holdProgress > 0 {
                    Text("\(Int(ceil(requiredHoldDuration * (1 - holdProgress))))s")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .monospacedDigit()
                }
            }
        }
        .onChange(of: isHolding) { holding in
            if holding {
                // Start pulse animation
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.6
                    ringScale = 1.1
                }
                
                // Haptic feedback on start
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .default
                )
                soundManager.playHoldFeedback()
            } else {
                // Stop animations
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseOpacity = 0
                    ringScale = 1.0
                }
                
                // Reset progress if not complete
                if holdProgress < 1.0 {
                    withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                        holdProgress = 0
                    }
                }
            }
        }
        .onChange(of: holdProgress) { progress in
            // Haptic feedback at milestones
            if progress > 0 && progress < 1 {
                let milestones: [Double] = [0.25, 0.5, 0.75]
                for milestone in milestones {
                    if abs(progress - milestone) < 0.02 {
                        NSHapticFeedbackManager.defaultPerformer.perform(
                            .generic,
                            performanceTime: .default
                        )
                        break
                    }
                }
            }
            
            // Complete
            if progress >= 1.0 {
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .default
                )
                soundManager.playMilestone()
                onComplete()
            }
        }
    }
}