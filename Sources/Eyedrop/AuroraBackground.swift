import SwiftUI

// MARK: - Aurora Background
/// Animated gradient background with flowing wave effect
/// Uses Canvas + TimelineView for smooth 60fps animation
/// Colors shift based on time of day for mystical vibes
struct AuroraBackground: View {
    @State private var phase: Double = 0
    
    // Get time-based palette
    private var timeColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<10: // Dawn - soft rose gold
            return [
                Color(red: 1.0, green: 0.75, blue: 0.6),   // Rose gold
                Color(red: 0.95, green: 0.6, blue: 0.7),   // Dusty rose
                Color(red: 0.8, green: 0.5, blue: 0.8),    // Lavender
                Color(red: 0.6, green: 0.4, blue: 0.7)     // Soft purple
            ]
        case 10..<17: // Day - vibrant energy
            return [
                Color(red: 1.0, green: 0.7, blue: 0.2),    // Golden
                Color(red: 0.95, green: 0.5, blue: 0.4),   // Coral
                Color(red: 0.7, green: 0.3, blue: 0.6),    // Magenta
                Color(red: 0.4, green: 0.2, blue: 0.7)     // Royal purple
            ]
        case 17..<21: // Evening - sunset vibes
            return [
                Color(red: 1.0, green: 0.4, blue: 0.3),    // Sunset orange
                Color(red: 0.9, green: 0.3, blue: 0.5),    // Hot pink
                Color(red: 0.6, green: 0.2, blue: 0.6),    // Deep magenta
                Color(red: 0.3, green: 0.1, blue: 0.5)     // Twilight purple
            ]
        default: // Night - cosmic depths
            return [
                Color(red: 0.6, green: 0.3, blue: 0.8),    // Electric purple
                Color(red: 0.4, green: 0.2, blue: 0.7),    // Deep violet
                Color(red: 0.2, green: 0.1, blue: 0.5),    // Midnight blue
                Color(red: 0.1, green: 0.05, blue: 0.3)    // Deep space
            ]
        }
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                // Use time for smooth continuous animation
                let time = timeline.date.timeIntervalSinceReferenceDate * 0.3 // Slower, more hypnotic
                
                // Get current palette
                let colors = timeColors
                
                // Draw multiple wave layers with varying dynamics
                for layer in 0..<5 {
                    let layerOffset = Double(layer) * 0.5
                    let speed = 0.2 + Double(layer) * 0.15
                    let opacity = 0.7 - Double(layer) * 0.12
                    
                    // More dramatic wave parameters for flowing effect
                    let waveAmplitude = size.height * (0.25 + Double(layer) * 0.05)
                    let waveFrequency = 1.2 + Double(layer) * 0.4
                    
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: size.height))
                    
                    // Create complex flowing wave path
                    for x in stride(from: 0, through: size.width, by: 2) {
                        let relativeX = x / size.width
                        
                        // Multiple sine waves for organic flow (simplified)
                        let wave1 = sin((relativeX * waveFrequency + time * speed + layerOffset) * .pi * 2) * waveAmplitude
                        let wave2 = sin((relativeX * 3.7 + time * speed * 0.8) * .pi) * waveAmplitude * 0.4
                        let wave3 = cos((relativeX * 5.3 + time * speed * 0.4) * .pi) * waveAmplitude * 0.2
                        
                        let y = size.height * 0.5 + wave1 + wave2 + wave3
                        
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.closeSubpath()
                    
                    let gradient = Gradient(stops: [
                        .init(color: colors[layer % 4].opacity(opacity), location: 0),
                        .init(color: colors[(layer + 1) % 4].opacity(opacity * 0.8), location: 0.4),
                        .init(color: colors[(layer + 2) % 4].opacity(opacity * 0.5), location: 0.7),
                        .init(color: colors[(layer + 3) % 4].opacity(opacity * 0.2), location: 1)
                    ])
                    
                    context.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: size.width * 0.3, y: 0),
                            endPoint: CGPoint(x: size.width * 0.7, y: size.height)
                        )
                    )
                    
                    // Varying blur for depth
                    context.addFilter(.blur(radius: 8 + CGFloat(layer) * 6))
                }
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
    }
}