#!/usr/bin/env swift

import SwiftUI
import AppKit

// MARK: - Color Palettes
let violetColors: [Color] = [
    Color(red: 0.42, green: 0.36, blue: 1.00),  // Blue-violet
    Color(red: 0.58, green: 0.18, blue: 0.98),  // Violet
    Color(red: 0.30, green: 0.14, blue: 0.88),  // Deep purple
    Color(red: 0.11, green: 0.07, blue: 0.42)   // Indigo
]

let emberColors: [Color] = [
    Color(red: 1.00, green: 0.75, blue: 0.25),  // Amber
    Color(red: 1.00, green: 0.45, blue: 0.10),  // Orange
    Color(red: 0.92, green: 0.25, blue: 0.18),  // Coral red
    Color(red: 0.50, green: 0.10, blue: 0.14)   // Deep wine
]

let emberParticleColors: [Color] = [
    Color(red: 1.0, green: 0.75, blue: 0.45),
    Color(red: 1.0, green: 0.45, blue: 0.20)
]

let violetParticleColors: [Color] = [
    Color(red: 0.60, green: 0.50, blue: 1.0),
    Color(red: 0.42, green: 0.36, blue: 1.0)
]

// MARK: - Aurora Canvas
struct StandaloneAurora: View {
    let colors: [Color]
    let time: Double

    var body: some View {
        Canvas { context, size in
            for layer in 0..<4 {
                let layerOffset = Double(layer) * 0.5
                let speed = 0.2 + Double(layer) * 0.15
                let opacity = 0.68 - Double(layer) * 0.12
                
                let waveAmplitude = size.height * (0.25 + Double(layer) * 0.05)
                let waveFrequency = 1.2 + Double(layer) * 0.4
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: size.height))
                
                for x in stride(from: 0, through: size.width, by: 4) {
                    let relativeX = x / size.width
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
                
                context.drawLayer { layerContext in
                    layerContext.addFilter(.blur(radius: 12 + CGFloat(layer) * 14))
                    layerContext.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: size.width * 0.3, y: 0),
                            endPoint: CGPoint(x: size.width * 0.7, y: size.height)
                        )
                    )
                }
            }

            // Light ribbons
            for ribbon in 0..<3 {
                let offset = Double(ribbon) * 0.28
                let speed = 0.12 + Double(ribbon) * 0.06
                let amplitude = size.height * (0.12 + Double(ribbon) * 0.035)
                let baseline = size.height * (0.36 + Double(ribbon) * 0.09)

                var path = Path()
                var didMove = false

                for x in stride(from: 0, through: size.width, by: 8) {
                    let relativeX = x / size.width
                    let wave = sin((relativeX * 1.8 + time * speed + offset) * .pi * 2) * amplitude
                    let shimmer = cos((relativeX * 4.6 + time * speed * 0.6) * .pi * 2) * amplitude * 0.22
                    let point = CGPoint(x: x, y: baseline + wave + shimmer)

                    if didMove {
                        path.addLine(to: point)
                    } else {
                        path.move(to: point)
                        didMove = true
                    }
                }

                let gradient = Gradient(stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: colors[(ribbon + 1) % colors.count].opacity(0.42), location: 0.28),
                    .init(color: Color.white.opacity(0.18), location: 0.5),
                    .init(color: colors[(ribbon + 2) % colors.count].opacity(0.36), location: 0.72),
                    .init(color: Color.clear, location: 1)
                ])

                context.drawLayer { layerContext in
                    layerContext.addFilter(.blur(radius: 7 + CGFloat(ribbon) * 3))
                    layerContext.stroke(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: 0, y: baseline),
                            endPoint: CGPoint(x: size.width, y: baseline)
                        ),
                        style: StrokeStyle(lineWidth: 22 - CGFloat(ribbon) * 4, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .drawingGroup()
    }
}

// MARK: - Particles
struct StandaloneParticles: View {
    let particleColors: [Color]
    let seed: Int

    var body: some View {
        Canvas { context, size in
            // Deterministic seeded pseudo-random distribution
            for i in 0..<18 {
                let fi = Double(i)
                let px = (sin(fi * 1.7 + Double(seed)) * 0.5 + 0.5) * size.width
                let py = (cos(fi * 2.3 + Double(seed)) * 0.5 + 0.5) * size.height
                let pSize = CGFloat(22.0 + sin(fi * 3.1) * 12.0)
                let opacity = 0.28 + sin(fi * 4.7) * 0.12

                let gradient = Gradient(stops: [
                    .init(color: particleColors[0].opacity(opacity), location: 0),
                    .init(color: particleColors[1].opacity(opacity * 0.55), location: 0.5),
                    .init(color: Color.clear, location: 1)
                ])

                context.fill(
                    Circle().path(in: CGRect(
                        x: px - pSize / 2,
                        y: py - pSize / 2,
                        width: pSize,
                        height: pSize
                    )),
                    with: .radialGradient(
                        gradient,
                        center: CGPoint(x: px, y: py),
                        startRadius: 0,
                        endRadius: pSize / 2
                    )
                )
            }
        }
    }
}

// MARK: - Overlay View
struct OverlayRenderer: View {
    let colors: [Color]
    let particleColors: [Color]
    let message: String
    let themeGlowColor: Color
    let time: Double
    let seed: Int
    let countdown: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let scale = width / 2880.0

        return ZStack {
            Color(red: 0.05, green: 0.03, blue: 0.08)
                .ignoresSafeArea()

            StandaloneAurora(colors: colors, time: time)
                .blur(radius: 12 * scale)
                .opacity(0.95)

            Rectangle()
                .fill(Color.black.opacity(0.12))
                .ignoresSafeArea()

            StandaloneParticles(particleColors: particleColors, seed: seed)
                .opacity(0.7)

            Text(message)
                .font(.system(size: 56 * scale, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.99, green: 0.96, blue: 0.91), Color(red: 0.99, green: 0.96, blue: 0.91).opacity(0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.99, green: 0.96, blue: 0.91).opacity(0.32), radius: 20 * scale)
                .shadow(color: Color(red: 0.99, green: 0.96, blue: 0.91).opacity(0.18), radius: 40 * scale)
                .shadow(color: themeGlowColor.opacity(0.38), radius: 34 * scale)
                .shadow(color: Color.black.opacity(0.3), radius: 6 * scale, x: 0, y: 3 * scale)

            // Bottom controls
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "speaker.wave.1.fill")
                        .font(.system(size: 16 * scale))
                        .foregroundColor(Color.white.opacity(0.3))
                        .padding(.leading, 32 * scale)
                    Spacer()
                    Text(countdown)
                        .font(.system(size: 18 * scale, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.trailing, 32 * scale)
                }
                .padding(.bottom, 28 * scale)
            }
        }
        .frame(width: width, height: height)
    }
}

// PNG writer: lockFocus / cacheDisplay render at the screen's backing scale (2x) in
// 16-bit, so raw output came out 5760x3600 and huge. The App Store only accepts exact
// 1280x800 / 1440x900 / 2560x1600 / 2880x1800, so resample into an 8-bit rep of the
// requested pixel size (the 2x render becomes free supersampling).
func writePNG(_ draw: (NSRect) -> Void, width: CGFloat, height: CGFloat, path: String) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else {
        print("❌ Failed to create bitmap rep for \(path)")
        return
    }
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    draw(NSRect(x: 0, y: 0, width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        print("❌ Failed to get PNG data for \(path)")
        return
    }
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    do {
        try png.write(to: url)
        print("✅ Saved \(path) — \(Int(width))x\(Int(height)), \(png.count / 1024) KB")
    } catch {
        print("❌ Error writing \(path): \(error)")
    }
}

func renderToFile(view: some View, width: CGFloat, height: CGFloat, path: String) {
    let hosting = NSHostingView(rootView: view)
    hosting.frame = CGRect(x: 0, y: 0, width: width, height: height)
    hosting.layoutSubtreeIfNeeded()

    guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
        print("❌ Failed to cache display for \(path)")
        return
    }
    hosting.cacheDisplay(in: hosting.bounds, to: rep)

    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(rep)
    writePNG({ image.draw(in: $0) }, width: width, height: height, path: path)
}

// 1. Violet at 2880x1800
let violetView2880 = OverlayRenderer(
    colors: violetColors,
    particleColors: violetParticleColors,
    message: "Depth silent",
    themeGlowColor: Color(red: 0.48, green: 0.30, blue: 1.0),
    time: 14.2,
    seed: 42,
    countdown: "14",
    width: 2880,
    height: 1800
)
renderToFile(view: violetView2880, width: 2880, height: 1800, path: "screenshots/violet-2880x1800.png")

// 2. Ember at 2880x1800
let emberView2880 = OverlayRenderer(
    colors: emberColors,
    particleColors: emberParticleColors,
    message: "Pulse softening",
    themeGlowColor: Color(red: 1.0, green: 0.62, blue: 0.4),
    time: 18.7,
    seed: 77,
    countdown: "14",
    width: 2880,
    height: 1800
)
renderToFile(view: emberView2880, width: 2880, height: 1800, path: "screenshots/ember-2880x1800.png")

// 3. Downscale for App Store sizes (2560x1600, 1440x900, 1280x800)
let sizes: [(CGFloat, CGFloat)] = [(2560, 1600), (1440, 900), (1280, 800)]
for (w, h) in sizes {
    let sw = Int(w)
    let sh = Int(h)
    
    let vView = OverlayRenderer(
        colors: violetColors,
        particleColors: violetParticleColors,
        message: "Depth silent",
        themeGlowColor: Color(red: 0.48, green: 0.30, blue: 1.0),
        time: 14.2,
        seed: 42,
        countdown: "14",
        width: w,
        height: h
    )
    renderToFile(view: vView, width: w, height: h, path: "screenshots/violet-\(sw)x\(sh).png")

    let eView = OverlayRenderer(
        colors: emberColors,
        particleColors: emberParticleColors,
        message: "Pulse softening",
        themeGlowColor: Color(red: 1.0, green: 0.62, blue: 0.4),
        time: 18.7,
        seed: 77,
        countdown: "14",
        width: w,
        height: h
    )
    renderToFile(view: eView, width: w, height: h, path: "screenshots/ember-\(sw)x\(sh).png")
}

// 4. Native 3420x2214 for Desktop / Stash
let violetView3420 = OverlayRenderer(
    colors: violetColors,
    particleColors: violetParticleColors,
    message: "Depth silent",
    themeGlowColor: Color(red: 0.48, green: 0.30, blue: 1.0),
    time: 14.2,
    seed: 42,
    countdown: "14",
    width: 3420,
    height: 2214
)
renderToFile(view: violetView3420, width: 3420, height: 2214, path: "/tmp/Spellbreak-violet-native.png")
