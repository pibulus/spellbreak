#!/usr/bin/env swift

import SwiftUI
import AppKit

// Define the app icon view
struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.7, blue: 0.9),
                    Color(red: 0.7, green: 0.5, blue: 0.9),
                    Color(red: 0.5, green: 0.3, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Soft glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .blur(radius: size * 0.05)
            
            // Eye shape
            ZStack {
                // Outer eye
                Ellipse()
                    .fill(Color.white)
                    .frame(width: size * 0.7, height: size * 0.4)
                    .shadow(color: .black.opacity(0.2), radius: size * 0.02, y: size * 0.01)
                
                // Iris
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.6, green: 0.4, blue: 0.9),
                                Color(red: 0.4, green: 0.2, blue: 0.7)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.15
                        )
                    )
                    .frame(width: size * 0.3, height: size * 0.3)
                
                // Pupil
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.12, height: size * 0.12)
                
                // Highlight
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.05, height: size * 0.05)
                    .offset(x: -size * 0.04, y: -size * 0.04)
            }
            
            // Subtle sparkles
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: size * 0.02, height: size * 0.02)
                    .offset(
                        x: size * (i == 0 ? -0.3 : i == 1 ? 0.25 : 0.1),
                        y: size * (i == 0 ? -0.2 : i == 1 ? -0.15 : 0.3)
                    )
                    .blur(radius: size * 0.005)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    }
}

// Generate icon at a specific size
func generateIcon(size: CGFloat, outputPath: String) {
    let iconView = AppIconView(size: size)
    let hostingView = NSHostingView(rootView: iconView)
    hostingView.frame = CGRect(x: 0, y: 0, width: size, height: size)
    
    let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
    
    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(bitmapRep)
    
    if let tiffData = image.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Generated icon at \(outputPath)")
    }
}

// Generate all required sizes
let sizes: [(size: CGFloat, name: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

let outputDir = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for (size, name) in sizes {
    generateIcon(size: size, outputPath: "\(outputDir)/\(name)")
}

print("\nTo create the .icns file, run:")
print("iconutil -c icns AppIcon.iconset")