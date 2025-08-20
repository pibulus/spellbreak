//
//  SpellTextGenerator.swift
//  Spellbreak
//
//  Generates mystical break messages based on time and moon phases.
//

import Foundation

struct SpellTextGenerator {
    
    // ===================================================================
    // MYSTICAL MESSAGE POOLS - Break messages with cosmic vibes
    // ===================================================================
    
    private static let mysticalMessages = [
        "The void blinks back",
        "Pixels dissolve at the edges",
        "Distance tastes like memory",
        "The spell thins here",
        "Reality buffers slowly",
        "Your rhythm syncs with elsewhere",
        "The screen dreams of forests",
        "Infinity lives in peripheral vision",
        "Time leaks between pixels",
        "The simulation pauses",
        "Digital ghosts need rest too",
        "Your aura extends past the screen",
        "The matrix loosens its grip",
        "Consciousness drifts sideways",
        "The portal needs closing",
        "Energy flows where focus goes",
        "The spell weakens with distance",
        "Your timeline branches here",
        "The algorithm releases you",
        "Static becomes signal"
    ]
    
    private static let playfulMessages = [
        "Your ancestors didn't stare at rectangles",
        "The simulation needs a break too",
        "Blink thrice for luck",
        "Screens can't follow you everywhere",
        "Plot twist: reality exists",
        "Your posture has opinions",
        "The pixels will manage without you",
        "Rectangles aren't natural shapes",
        "Your third eye sends regards",
        "The void appreciates your attention",
        "Computers dream of electric sheep",
        "Your retinas are unionizing",
        "The cursor can wait",
        "Photons scatter like startled birds",
        "Your corneas called a meeting",
        "The internet will still be there",
        "Meatspace misses you",
        "Your body exists, allegedly",
        "The screen isn't going anywhere",
        "ctrl+alt+delete your gaze"
    ]
    
    private static let directMessages = [
        "Eyes elsewhere now",
        "Break the pixel spell",
        "Focus dissolves. Let it",
        "Time to unfocus",
        "Look through, not at",
        "Release the screen",
        "Gaze into actual distance",
        "Stop. Breathe. Blink",
        "Turn away",
        "Let your eyes wander",
        "Find something far",
        "The horizon calls",
        "Shift your focal plane",
        "Exit the trance",
        "Break eye contact with the void",
        "Look at nothing specific",
        "Distance heals",
        "Periphery needs attention",
        "Close your eyes. Count to ten",
        "Reality check initiated"
    ]
    
    private static let temporalMessages = [
        // Morning
        "Dawn breaks the digital spell",
        "Morning light beats screen glow",
        "The day exists beyond pixels",
        
        // Afternoon
        "Afternoon drift is natural",
        "Peak hours for distance gazing",
        "The sun doesn't render in RGB",
        
        // Evening
        "Twilight dissolves the harsh edges",
        "Evening eyes seek softer light",
        "Golden hour isn't on your screen",
        
        // Night
        "The moon pulls your gaze",
        "Darkness is gentler than backlight",
        "Night vision needs no pixels",
        "Stars don't need refreshing",
        "The void gazes also into you",
        
        // Anytime
        "Time moves differently out there",
        "This moment won't compile",
        "The present has no loading screen",
        "Now exists in analog"
    ]
    
    // ===================================================================
    // MOON PHASE CALCULATION
    // ===================================================================
    
    private static func getMoonPhase() -> String {
        // Simple moon phase calculation (approximate)
        let calendar = Calendar.current
        let now = Date()
        
        // Known new moon date (Jan 11, 2024)
        let knownNewMoon = calendar.date(from: DateComponents(year: 2024, month: 1, day: 11))!
        let daysSinceNewMoon = calendar.dateComponents([.day], from: knownNewMoon, to: now).day ?? 0
        
        // Lunar cycle is ~29.53 days
        let lunarCycle = 29.53
        let moonAge = Double(daysSinceNewMoon).truncatingRemainder(dividingBy: lunarCycle)
        
        switch moonAge {
        case 0..<2: return "new"
        case 2..<9: return "waxing"
        case 9..<11: return "firstQuarter"
        case 11..<18: return "waxingGibbous"
        case 18..<20: return "full"
        case 20..<27: return "waning"
        default: return "waningCrescent"
        }
    }
    
    // ===================================================================
    // SPECIAL MOON MESSAGES
    // ===================================================================
    
    private static let moonMessages = [
        "full": [
            "The moon owns your retinas tonight",
            "Full moon breaks all spells",
            "Lunar gravity exceeds screen pull"
        ],
        "new": [
            "New moon, new perspective",
            "Darkness reveals more than light",
            "The void is especially deep tonight"
        ]
    ]
    
    // ===================================================================
    // PUBLIC METHODS
    // ===================================================================
    
    static func generateMessage(
        breakCount: Int = 0,
        skippedCount: Int = 0,
        lastBreakInterval: TimeInterval? = nil
    ) -> String {
        
        var pool: [String] = []
        
        // Simple weighted selection: 60% mystical/playful, 40% direct/temporal
        let magicRoll = Int.random(in: 1...10)
        
        if magicRoll <= 6 {
            // 60% - Mystical or playful
            pool = mysticalMessages + playfulMessages
        } else {
            // 40% - Direct or temporal
            pool = directMessages + temporalMessages
        }
        
        // Add context modifiers
        
        // If been too long (>40 mins), add more direct messages
        if let interval = lastBreakInterval, interval > 2400 {
            pool += [
                "It's been too long",
                "The spell has you",
                "Break free. Now",
                "Your body is trying to tell you something"
            ]
        }
        
        // If many breaks skipped, get slightly more insistent
        if skippedCount > 3 {
            pool += [
                "The matrix has you",
                "You've been hypnotized",
                "Break the cycle",
                "The spell grows stronger"
            ]
        }
        
        // Moon phase special messages
        let moonPhase = getMoonPhase()
        if moonPhase == "full", let fullMoonMessages = moonMessages["full"] {
            pool += fullMoonMessages
        } else if moonPhase == "new", let newMoonMessages = moonMessages["new"] {
            pool += newMoonMessages
        }
        
        // Time-based flavor (just add a few contextual ones)
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5:
            pool += ["3am thoughts need distance", "The witching hour watches"]
        case 5..<9:
            pool += ["Dawn breaks the spell", "Morning pixels taste different"]
        case 12..<14:
            pool += ["Noon shadows are shortest", "Peak reality hours"]
        case 17..<20:
            pool += ["Golden hour isn't on screen", "Evening dissolves edges"]
        case 22..<24:
            pool += ["Night thoughts drift further", "The void is patient"]
        default:
            break
        }
        
        // Select a random message from the pool
        return pool.randomElement() ?? "Break the spell"
    }
    
    static func generateSpellName() -> String {
        let spells = [
            "Digital Unbinding",
            "Screen Liberation Ritual", 
            "Pixel Dispersion",
            "Focus Restoration",
            "Vision Renewal Protocol",
            "Retinal Rebellion",
            "The Great Unfocusing",
            "Photon Scattering Technique",
            "Monitor Exorcism",
            "Blue Light Banishment"
        ]
        return spells.randomElement() ?? "Digital Unbinding"
    }
}
