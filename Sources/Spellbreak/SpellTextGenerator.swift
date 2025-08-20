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
        "Your ancestors looked at horizons",
        "The simulation needs rest too",
        "Blink with intention",
        "Screens can't follow you here",
        "Reality renders differently",
        "Your body keeps the score",
        "The pixels will wait",
        "Rectangles aren't found in nature",
        "The third eye needs distance",
        "The void returns your gaze",
        "Digital dreams need pauses",
        "Your vision has limits",
        "The cursor can wait",
        "Photons scatter naturally",
        "Your focus has wandered",
        "The internet remains",
        "Physical space exists",
        "Your body remembers stillness",
        "The screen stays put",
        "Reset your focal length"
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
            "The moon pulls stronger tonight",
            "Full moon breaks the spell",
            "Lunar light exceeds screen glow"
        ],
        "new": [
            "New moon, new perspective",
            "Darkness reveals distance",
            "The void deepens tonight"
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
                "The spell deepens",
                "Time to break free",
                "Your body knows"
            ]
        }
        
        // If many breaks skipped, get slightly more insistent
        if skippedCount > 3 {
            pool += [
                "The pattern holds you",
                "Deep in the trance",
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
            pool += ["Late thoughts need space", "The quiet hour arrives"]
        case 5..<9:
            pool += ["Dawn breaks the spell", "Morning light differs"]
        case 12..<14:
            pool += ["Noon light is real", "Midday clarity calls"]
        case 17..<20:
            pool += ["Golden hour waits outside", "Evening softens edges"]
        case 22..<24:
            pool += ["Night thoughts drift", "The day releases"]
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
