#!/usr/bin/env swift

import AppKit
import CoreGraphics
import CoreText

// MARK: - App Store Story Card Generator
// Generates 5 high-impact marketing cards at 2880x1800 and 1440x900

struct CardSpec {
    let filename: String
    let badge: String
    let headline: String
    let subheadline: String
    let type: CardType
}

enum CardType {
    case heroOverlay(imageName: String)
    case tarotMessages
    case holdToSkip
    case shaderTriptych
    case cartridgeManifesto
}

let cards: [CardSpec] = [
    CardSpec(
        filename: "01-break-the-spell",
        badge: "✨ REST YOUR EYES & RESET YOUR POSTURE",
        headline: "Your shoulders holding court since Tuesday?",
        subheadline: "Gentle full-screen aurora waves that remind you to take a breath and unclench.",
        type: .heroOverlay(imageName: "screenshots/aurora-2880x1800.png")
    ),
    CardSpec(
        filename: "02-street-smart-wisdom",
        badge: "💬 REAL TALK, NOT WELLNESS LECTURES",
        headline: "Messages that know your patterns.",
        subheadline: "Short, punchy reminders that actually help you stretch, rest, and reset.",
        type: .tarotMessages
    ),
    CardSpec(
        filename: "03-hold-to-skip",
        badge: "⏳ GENTLE FRICTION",
        headline: "Hard to ignore. Easy to leave.",
        subheadline: "Hold down the ring for a couple of seconds to skip. Just enough time to think twice.",
        type: .holdToSkip
    ),
    CardSpec(
        filename: "04-living-shaders",
        badge: "🎨 THREE CALMING VISUAL THEMES",
        headline: "Colors that shift with the day.",
        subheadline: "Dawn rose, golden midday, cosmic starlight, and coral lava. Plus Surprise Me.",
        type: .shaderTriptych
    ),
    CardSpec(
        filename: "05-no-subscriptions",
        badge: "🔒 100% PRIVATE • NO SUBSCRIPTIONS",
        headline: "Pay once. Yours forever.",
        subheadline: "$19.99 one-time. No accounts, no monthly fees, and zero tracking.",
        type: .cartridgeManifesto
    )
]

func drawCard(spec: CardSpec, width: CGFloat, height: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }

    let scale = width / 2880.0

    // 1. Background gradient
    let bgColors = [
        NSColor(red: 0.05, green: 0.03, blue: 0.09, alpha: 1.0).cgColor,
        NSColor(red: 0.09, green: 0.05, blue: 0.16, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.02, blue: 0.08, alpha: 1.0).cgColor
    ]
    let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: bgColors as CFArray,
                            locations: [0.0, 0.5, 1.0])!
    ctx.drawLinearGradient(bgGrad,
                           start: CGPoint(x: width * 0.5, y: height),
                           end: CGPoint(x: width * 0.5, y: 0),
                           options: [])

    // 2. Ambient top glow orb
    let glowColors = [
        NSColor(red: 0.65, green: 0.35, blue: 0.95, alpha: 0.18).cgColor,
        NSColor(red: 0.95, green: 0.45, blue: 0.70, alpha: 0.08).cgColor,
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
    ]
    let glowGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: glowColors as CFArray,
                              locations: [0.0, 0.4, 1.0])!
    ctx.drawRadialGradient(glowGrad,
                           startCenter: CGPoint(x: width * 0.5, y: height * 0.85),
                           startRadius: 0,
                           endCenter: CGPoint(x: width * 0.5, y: height * 0.85),
                           endRadius: width * 0.55,
                           options: [])

    // 3. Header Text Section
    let topY = height - (140 * scale)

    // Badge
    let badgeFont = NSFont.systemFont(ofSize: 22 * scale, weight: .bold)
    let badgeAttrs: [NSAttributedString.Key: Any] = [
        .font: badgeFont,
        .foregroundColor: NSColor(red: 1.0, green: 0.75, blue: 0.35, alpha: 0.95),
        .kern: 2.0 * scale
    ]
    let badgeString = NSAttributedString(string: spec.badge, attributes: badgeAttrs)
    let badgeSize = badgeString.size()
    let badgeRect = CGRect(x: (width - badgeSize.width) / 2, y: topY - badgeSize.height, width: badgeSize.width, height: badgeSize.height)
    badgeString.draw(in: badgeRect)

    // Headline
    let headlineFont = NSFont(name: "NewYork-Bold", size: 62 * scale) ?? NSFont.systemFont(ofSize: 62 * scale, weight: .black)
    let headlineStyle = NSMutableParagraphStyle()
    headlineStyle.alignment = .center
    let headlineAttrs: [NSAttributedString.Key: Any] = [
        .font: headlineFont,
        .foregroundColor: NSColor(red: 0.99, green: 0.96, blue: 0.91, alpha: 1.0),
        .paragraphStyle: headlineStyle
    ]
    let headlineString = NSAttributedString(string: spec.headline, attributes: headlineAttrs)
    let headlineRect = CGRect(x: width * 0.08, y: badgeRect.minY - (90 * scale), width: width * 0.84, height: 80 * scale)
    headlineString.draw(in: headlineRect)

    // Subheadline
    let subFont = NSFont.systemFont(ofSize: 28 * scale, weight: .medium)
    let subStyle = NSMutableParagraphStyle()
    subStyle.alignment = .center
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: subFont,
        .foregroundColor: NSColor(red: 0.88, green: 0.82, blue: 0.96, alpha: 0.78),
        .paragraphStyle: subStyle
    ]
    let subString = NSAttributedString(string: spec.subheadline, attributes: subAttrs)
    let subRect = CGRect(x: width * 0.12, y: headlineRect.minY - (54 * scale), width: width * 0.76, height: 50 * scale)
    subString.draw(in: subRect)

    // 4. Main Body Content Area
    let contentY: CGFloat = 80 * scale
    let contentHeight = subRect.minY - contentY - (40 * scale)
    let contentRect = CGRect(x: width * 0.10, y: contentY, width: width * 0.80, height: contentHeight)

    switch spec.type {
    case .heroOverlay(let imageName):
        drawHeroOverlay(imageName: imageName, in: contentRect, scale: scale, ctx: ctx)
    case .tarotMessages:
        drawTarotCards(in: contentRect, scale: scale, ctx: ctx)
    case .holdToSkip:
        drawHoldToSkipCard(in: contentRect, scale: scale, ctx: ctx)
    case .shaderTriptych:
        drawShaderTriptych(in: contentRect, scale: scale, ctx: ctx)
    case .cartridgeManifesto:
        drawCartridgeManifesto(in: contentRect, scale: scale, ctx: ctx)
    }

    image.unlockFocus()
    return image
}

func drawFramedImage(_ img: NSImage, in rect: CGRect, cornerRadius: CGFloat, ctx: CGContext) {
    ctx.saveGState()
    
    // Shadow
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 50, color: NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.65).cgColor)
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    
    // Clip and draw image
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    img.draw(in: rect, from: NSRect(origin: .zero, size: img.size), operation: .copy, fraction: 1.0)
    ctx.restoreGState()

    // Neon border glow
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.setLineWidth(2.5)
    ctx.setStrokeColor(NSColor(red: 0.85, green: 0.65, blue: 1.0, alpha: 0.35).cgColor)
    ctx.addPath(path)
    ctx.strokePath()

    ctx.restoreGState()
}

func drawHeroOverlay(imageName: String, in rect: CGRect, scale: CGFloat, ctx: CGContext) {
    if let img = NSImage(contentsOfFile: imageName) {
        drawFramedImage(img, in: rect, cornerRadius: 28 * scale, ctx: ctx)
    }
}

func drawTarotCards(in rect: CGRect, scale: CGFloat, ctx: CGContext) {
    let quotes = [
        ("THE TRANCE GETS COMFORTABLE", "01 / 20-20-20 RULE", "Look away from the screen at something 20 feet away to rest your eyes."),
        ("YOUR SHOULDERS HOLDING COURT SINCE TUESDAY?", "02 / POSTURE RESET", "Drop your shoulders away from your ears. Unclench your jaw."),
        ("SCREEN'S GOT YOUR NUMBER", "03 / TAKE FIVE", "Step away, grab some water, and let your body catch up.")
    ]

    let cardWidth = (rect.width - (40 * scale * 2)) / 3
    let cardHeight = rect.height * 0.88
    let cardY = rect.midY - (cardHeight / 2)

    for (i, quote) in quotes.enumerated() {
        let cardX = rect.minX + CGFloat(i) * (cardWidth + (40 * scale))
        let cardRect = CGRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight)

        ctx.saveGState()
        // Card Shadow
        ctx.setShadow(offset: CGSize(width: 0, height: -16 * scale), blur: 36 * scale, color: NSColor.black.withAlphaComponent(0.6).cgColor)
        let path = CGPath(roundedRect: cardRect, cornerWidth: 24 * scale, cornerHeight: 24 * scale, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(NSColor(red: 0.13, green: 0.08, blue: 0.22, alpha: 0.85).cgColor)
        ctx.fillPath()

        // Border
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.setLineWidth(2 * scale)
        let borderColors = [
            NSColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 0.4),
            NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.4),
            NSColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 0.4)
        ]
        ctx.setStrokeColor(borderColors[i % 3].cgColor)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()

        // Card Content
        let pad = 36 * scale
        
        // Category / Subtitle
        let catFont = NSFont.systemFont(ofSize: 16 * scale, weight: .bold)
        let catAttrs: [NSAttributedString.Key: Any] = [
            .font: catFont,
            .foregroundColor: borderColors[i % 3],
            .kern: 1.5 * scale
        ]
        let catString = NSAttributedString(string: quote.1, attributes: catAttrs)
        catString.draw(at: CGPoint(x: cardX + pad, y: cardY + cardHeight - pad - 20 * scale))

        // Big Quote
        let quoteFont = NSFont(name: "NewYork-Bold", size: 34 * scale) ?? NSFont.systemFont(ofSize: 34 * scale, weight: .bold)
        let quoteStyle = NSMutableParagraphStyle()
        quoteStyle.lineSpacing = 6 * scale
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: quoteFont,
            .foregroundColor: NSColor(red: 0.99, green: 0.96, blue: 0.91, alpha: 0.95),
            .paragraphStyle: quoteStyle
        ]
        let quoteString = NSAttributedString(string: quote.0, attributes: quoteAttrs)
        let quoteRect = CGRect(x: cardX + pad, y: cardY + cardHeight * 0.35, width: cardWidth - (pad * 2), height: cardHeight * 0.45)
        quoteString.draw(in: quoteRect)

        // Description
        let descFont = NSFont.systemFont(ofSize: 18 * scale, weight: .regular)
        let descStyle = NSMutableParagraphStyle()
        descStyle.lineSpacing = 4 * scale
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: descFont,
            .foregroundColor: NSColor(red: 0.85, green: 0.80, blue: 0.92, alpha: 0.65),
            .paragraphStyle: descStyle
        ]
        let descString = NSAttributedString(string: quote.2, attributes: descAttrs)
        let descRect = CGRect(x: cardX + pad, y: cardY + pad + 10 * scale, width: cardWidth - (pad * 2), height: cardHeight * 0.25)
        descString.draw(in: descRect)
    }
}

func drawHoldToSkipCard(in rect: CGRect, scale: CGFloat, ctx: CGContext) {
    if let bgImg = NSImage(contentsOfFile: "screenshots/cosmic-2880x1800.png") {
        drawFramedImage(bgImg, in: rect, cornerRadius: 28 * scale, ctx: ctx)
    }

    // Overlay glowing hold ring in center
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let ringRadius: CGFloat = 110 * scale

    ctx.saveGState()
    // Ring glow
    ctx.setShadow(offset: .zero, blur: 30 * scale, color: NSColor(red: 1.0, green: 0.5, blue: 0.8, alpha: 0.8).cgColor)
    
    // Background track
    ctx.setLineWidth(10 * scale)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    ctx.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
    ctx.strokePath()

    // Progress arc (68% hold)
    let startAngle = -CGFloat.pi / 2
    let endAngle = startAngle + (CGFloat.pi * 2 * 0.68)
    ctx.setStrokeColor(NSColor(red: 1.0, green: 0.45, blue: 0.75, alpha: 1.0).cgColor)
    ctx.setLineCap(.round)
    ctx.addArc(center: center, radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
    ctx.strokePath()

    ctx.restoreGState()

    // Hold Ring Text
    let holdFont = NSFont(name: "NewYork-Medium", size: 36 * scale) ?? NSFont.systemFont(ofSize: 36 * scale, weight: .bold)
    let holdAttrs: [NSAttributedString.Key: Any] = [
        .font: holdFont,
        .foregroundColor: NSColor(red: 0.99, green: 0.96, blue: 0.91, alpha: 1.0)
    ]
    let holdStr = NSAttributedString(string: "HOLD TO SKIP", attributes: holdAttrs)
    let holdSize = holdStr.size()
    holdStr.draw(at: CGPoint(x: center.x - (holdSize.width / 2), y: center.y - (holdSize.height / 2) + (10 * scale)))

    let pctFont = NSFont.systemFont(ofSize: 20 * scale, weight: .bold)
    let pctAttrs: [NSAttributedString.Key: Any] = [
        .font: pctFont,
        .foregroundColor: NSColor(red: 1.0, green: 0.65, blue: 0.85, alpha: 0.85)
    ]
    let pctStr = NSAttributedString(string: "68%", attributes: pctAttrs)
    let pctSize = pctStr.size()
    pctStr.draw(at: CGPoint(x: center.x - (pctSize.width / 2), y: center.y - (holdSize.height / 2) - (24 * scale)))
}

func drawShaderTriptych(in rect: CGRect, scale: CGFloat, ctx: CGContext) {
    let images = [
        ("screenshots/aurora-2880x1800.png", "AURORA", "Dawn & Day Flow"),
        ("screenshots/cosmic-2880x1800.png", "COSMIC", "Deep Night Starlight"),
        ("screenshots/lava-2880x1800.png", "LAVA", "Warm Coral Hearth")
    ]

    let itemWidth = (rect.width - (30 * scale * 2)) / 3
    let itemHeight = rect.height * 0.90
    let itemY = rect.midY - (itemHeight / 2)

    for (i, item) in images.enumerated() {
        let itemX = rect.minX + CGFloat(i) * (itemWidth + (30 * scale))
        let itemRect = CGRect(x: itemX, y: itemY, width: itemWidth, height: itemHeight)

        if let img = NSImage(contentsOfFile: item.0) {
            drawFramedImage(img, in: itemRect, cornerRadius: 22 * scale, ctx: ctx)
        }

        // Title Pill at bottom
        let pillHeight = 64 * scale
        let pillRect = CGRect(x: itemX + (20 * scale), y: itemY + (20 * scale), width: itemWidth - (40 * scale), height: pillHeight)

        ctx.saveGState()
        let path = CGPath(roundedRect: pillRect, cornerWidth: 16 * scale, cornerHeight: 16 * scale, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(NSColor(red: 0.08, green: 0.04, blue: 0.14, alpha: 0.88).cgColor)
        ctx.fillPath()
        ctx.setLineWidth(1.5 * scale)
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()

        let titleFont = NSFont.systemFont(ofSize: 18 * scale, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor(red: 0.99, green: 0.96, blue: 0.91, alpha: 0.95),
            .kern: 1.2 * scale
        ]
        let titleStr = NSAttributedString(string: item.1, attributes: titleAttrs)
        titleStr.draw(at: CGPoint(x: pillRect.minX + (16 * scale), y: pillRect.midY - (4 * scale)))

        let descFont = NSFont.systemFont(ofSize: 13 * scale, weight: .medium)
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: descFont,
            .foregroundColor: NSColor(red: 0.85, green: 0.80, blue: 0.95, alpha: 0.65)
        ]
        let descStr = NSAttributedString(string: item.2, attributes: descAttrs)
        descStr.draw(at: CGPoint(x: pillRect.minX + (16 * scale), y: pillRect.minY + (10 * scale)))
    }
}

func drawCartridgeManifesto(in rect: CGRect, scale: CGFloat, ctx: CGContext) {
    let pillars = [
        ("🔒 100% PRIVATE", "No accounts, no tracking, no ads. Everything stays securely on your Mac."),
        ("🎨 3 CALMING THEMES", "Aurora, Cosmic, and Lava themes with colors that adjust automatically throughout the day."),
        ("⏳ GENTLE FRICTION", "Hold-to-skip ring gives just enough pause to help you take your break without trapping you."),
        ("💎 NO SUBSCRIPTIONS", "A single $19.99 purchase. Own it forever without recurring monthly or yearly fees.")
    ]

    let boxWidth = (rect.width - (30 * scale)) / 2
    let boxHeight = (rect.height - (30 * scale)) / 2

    for (i, p) in pillars.enumerated() {
        let col = CGFloat(i % 2)
        let row = CGFloat(1 - (i / 2))

        let boxX = rect.minX + col * (boxWidth + (30 * scale))
        let boxY = rect.minY + row * (boxHeight + (30 * scale))
        let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 30 * scale, color: NSColor.black.withAlphaComponent(0.5).cgColor)
        let path = CGPath(roundedRect: boxRect, cornerWidth: 20 * scale, cornerHeight: 20 * scale, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(NSColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 0.85).cgColor)
        ctx.fillPath()

        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.setLineWidth(1.8 * scale)
        ctx.setStrokeColor(NSColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 0.35).cgColor)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()

        let pad = 36 * scale
        let titleFont = NSFont.systemFont(ofSize: 22 * scale, weight: .bold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor(red: 1.0, green: 0.75, blue: 0.4, alpha: 0.95),
            .kern: 1.2 * scale
        ]
        let titleStr = NSAttributedString(string: p.0, attributes: titleAttrs)
        titleStr.draw(at: CGPoint(x: boxX + pad, y: boxY + boxHeight - pad - (20 * scale)))

        let descFont = NSFont.systemFont(ofSize: 20 * scale, weight: .regular)
        let descStyle = NSMutableParagraphStyle()
        descStyle.lineSpacing = 6 * scale
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: descFont,
            .foregroundColor: NSColor(red: 0.92, green: 0.88, blue: 0.98, alpha: 0.85),
            .paragraphStyle: descStyle
        ]
        let descStr = NSAttributedString(string: p.1, attributes: descAttrs)
        let descRect = CGRect(x: boxX + pad, y: boxY + pad, width: boxWidth - (pad * 2), height: boxHeight - pad - (60 * scale))
        descStr.draw(in: descRect)
    }
}

// MARK: - Execution

let fileManager = FileManager.default
let outputDir = "screenshots/appstore"
try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

print("🎨 Rendering App Store Story Cards...")

for card in cards {
    print("📸 Rendering: \(card.filename)...")
    
    // 1. 2880x1800 (16:10 Retina)
    let img2880 = drawCard(spec: card, width: 2880, height: 1800)
    if let tiff = img2880.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/\(card.filename)-2880x1800.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("   ✅ Created: \(path)")
    }

    // 2. 1440x900 (16:10 Standard)
    let img1440 = drawCard(spec: card, width: 1440, height: 900)
    if let tiff = img1440.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/\(card.filename)-1440x900.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("   ✅ Created: \(path)")
    }
}

print("\n✨ All App Store Story Cards generated in \(outputDir)/")
