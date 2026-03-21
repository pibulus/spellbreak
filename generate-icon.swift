#!/usr/bin/env swift

// Generates Spellbreak app icon at all required sizes
// Mystical crystal ball with aurora gradient - pastel-punk aesthetic

import AppKit

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))

    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext

    // Background: deep dark purple with subtle gradient
    let bgColors = [
        NSColor(red: 0.12, green: 0.08, blue: 0.20, alpha: 1.0).cgColor,
        NSColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1.0).cgColor,
    ]
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: bgColors as CFArray,
                                 locations: [0.0, 1.0])!

    // Rounded rect background
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                         cornerWidth: s * 0.22, cornerHeight: s * 0.22,
                         transform: nil)
    context.addPath(bgPath)
    context.clip()
    context.drawLinearGradient(bgGradient,
                               start: CGPoint(x: s/2, y: s),
                               end: CGPoint(x: s/2, y: 0),
                               options: [])

    // Aurora waves in background (subtle)
    for i in 0..<3 {
        let waveY = s * (0.35 + CGFloat(i) * 0.12)
        let wavePath = CGMutablePath()
        wavePath.move(to: CGPoint(x: 0, y: waveY))
        wavePath.addCurve(to: CGPoint(x: s, y: waveY + s * 0.08),
                          control1: CGPoint(x: s * 0.3, y: waveY + s * 0.15),
                          control2: CGPoint(x: s * 0.7, y: waveY - s * 0.1))
        wavePath.addLine(to: CGPoint(x: s, y: 0))
        wavePath.addLine(to: CGPoint(x: 0, y: 0))
        wavePath.closeSubpath()

        let waveColors: [[CGFloat]] = [
            [0.95, 0.4, 0.8, 0.12],   // Pink
            [1.0, 0.6, 0.5, 0.10],    // Coral
            [0.7, 0.4, 0.9, 0.08],    // Purple
        ]
        let c = waveColors[i]
        context.setFillColor(NSColor(red: c[0], green: c[1], blue: c[2], alpha: c[3]).cgColor)
        context.addPath(wavePath)
        context.fillPath()
    }

    // Central crystal ball / orb
    let orbRadius = s * 0.28
    let orbCenter = CGPoint(x: s * 0.5, y: s * 0.52)

    // Outer glow
    for r in stride(from: orbRadius * 1.8, through: orbRadius * 1.1, by: -2) {
        let alpha = 0.03 * (1.0 - (r - orbRadius) / (orbRadius * 0.8))
        context.setFillColor(NSColor(red: 0.9, green: 0.5, blue: 0.9, alpha: alpha).cgColor)
        context.fillEllipse(in: CGRect(x: orbCenter.x - r, y: orbCenter.y - r,
                                        width: r * 2, height: r * 2))
    }

    // Orb body with gradient
    let orbRect = CGRect(x: orbCenter.x - orbRadius, y: orbCenter.y - orbRadius,
                          width: orbRadius * 2, height: orbRadius * 2)

    context.saveGState()
    context.addEllipse(in: orbRect)
    context.clip()

    let orbColors = [
        NSColor(red: 0.3, green: 0.15, blue: 0.5, alpha: 0.9).cgColor,
        NSColor(red: 0.15, green: 0.1, blue: 0.35, alpha: 0.95).cgColor,
    ]
    let orbGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: orbColors as CFArray,
                                  locations: [0.0, 1.0])!
    context.drawRadialGradient(orbGradient,
                                startCenter: CGPoint(x: orbCenter.x - orbRadius * 0.2,
                                                     y: orbCenter.y + orbRadius * 0.3),
                                startRadius: 0,
                                endCenter: orbCenter,
                                endRadius: orbRadius,
                                options: [])

    // Inner aurora swirl
    for i in 0..<5 {
        let angle = CGFloat(i) * .pi * 2.0 / 5.0
        let swirls: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
            (0.95, 0.4, 0.8),   // Hot pink
            (1.0, 0.6, 0.5),    // Coral
            (0.7, 0.4, 0.9),    // Purple
            (1.0, 0.7, 0.4),    // Gold
            (0.4, 0.7, 1.0),    // Blue
        ]
        let c = swirls[i]
        let swirlCenter = CGPoint(x: orbCenter.x + cos(angle) * orbRadius * 0.4,
                                   y: orbCenter.y + sin(angle) * orbRadius * 0.4)
        let swirlRadius = orbRadius * 0.35

        let swirlColors = [
            NSColor(red: c.r, green: c.g, blue: c.b, alpha: 0.4).cgColor,
            NSColor(red: c.r, green: c.g, blue: c.b, alpha: 0.0).cgColor,
        ]
        let swirlGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: swirlColors as CFArray,
                                        locations: [0.0, 1.0])!
        context.drawRadialGradient(swirlGradient,
                                    startCenter: swirlCenter,
                                    startRadius: 0,
                                    endCenter: swirlCenter,
                                    endRadius: swirlRadius,
                                    options: [])
    }

    context.restoreGState()

    // Orb rim / edge highlight
    context.setStrokeColor(NSColor(red: 0.9, green: 0.6, blue: 1.0, alpha: 0.3).cgColor)
    context.setLineWidth(s * 0.008)
    context.strokeEllipse(in: orbRect)

    // Specular highlight on orb (top-left)
    let highlightRect = CGRect(x: orbCenter.x - orbRadius * 0.55,
                                y: orbCenter.y + orbRadius * 0.15,
                                width: orbRadius * 0.6,
                                height: orbRadius * 0.5)
    context.saveGState()
    context.addEllipse(in: highlightRect)
    context.clip()
    let highlightColors = [
        NSColor(white: 1.0, alpha: 0.35).cgColor,
        NSColor(white: 1.0, alpha: 0.0).cgColor,
    ]
    let highlightGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: highlightColors as CFArray,
                                        locations: [0.0, 1.0])!
    context.drawRadialGradient(highlightGradient,
                                startCenter: CGPoint(x: highlightRect.midX, y: highlightRect.midY),
                                startRadius: 0,
                                endCenter: CGPoint(x: highlightRect.midX, y: highlightRect.midY),
                                endRadius: highlightRect.width * 0.5,
                                options: [])
    context.restoreGState()

    // Small sparkle dots
    let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat, alpha: CGFloat)] = [
        (0.72, 0.78, 0.025, 0.9),
        (0.28, 0.75, 0.018, 0.7),
        (0.65, 0.28, 0.020, 0.6),
        (0.35, 0.30, 0.015, 0.5),
        (0.80, 0.55, 0.012, 0.4),
        (0.20, 0.50, 0.014, 0.5),
    ]
    for sp in sparkles {
        let spSize = s * sp.size
        let spRect = CGRect(x: s * sp.x - spSize/2, y: s * sp.y - spSize/2,
                             width: spSize, height: spSize)
        // Glow
        let glowSize = spSize * 3
        let glowRect = CGRect(x: s * sp.x - glowSize/2, y: s * sp.y - glowSize/2,
                               width: glowSize, height: glowSize)
        let glowColors = [
            NSColor(white: 1.0, alpha: sp.alpha * 0.3).cgColor,
            NSColor(white: 1.0, alpha: 0.0).cgColor,
        ]
        let glowGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: glowColors as CFArray,
                                       locations: [0.0, 1.0])!
        context.drawRadialGradient(glowGradient,
                                    startCenter: CGPoint(x: spRect.midX, y: spRect.midY),
                                    startRadius: 0,
                                    endCenter: CGPoint(x: glowRect.midX, y: glowRect.midY),
                                    endRadius: glowSize / 2,
                                    options: [])
        // Dot
        context.setFillColor(NSColor(white: 1.0, alpha: sp.alpha).cgColor)
        context.fillEllipse(in: spRect)
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, path: String, size: Int) {
    let resized = NSImage(size: NSSize(width: size, height: size))
    resized.lockFocus()
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
               from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
               operation: .copy, fraction: 1.0)
    resized.unlockFocus()

    guard let tiffData = resized.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for size \(size)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Created: \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

// Generate at high resolution, then scale down for each size
let masterIcon = generateIcon(size: 1024)
let iconDir = "Assets.xcassets/AppIcon.appiconset"

// All required macOS icon sizes
let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for size in sizes {
    savePNG(masterIcon, path: "\(iconDir)/\(size.name).png", size: size.px)
}

print("\nAll icons generated!")
