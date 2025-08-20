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
        "The void holds its breath, waiting",
        "Pixels dissolve like sugar in rain",
        "Distance remembers what screens forget",
        "The spell breaks where light bends",
        "Reality loads one frame at a time",
        "Your pulse finds older rhythms",
        "Screens dream of the forests they'll never be",
        "Infinity sleeps in your peripheral vision",
        "Time pools in the spaces between refresh rates",
        "Even simulations need to dream",
        "Ghost light flickers at the edge of focus",
        "Your attention casts shadows elsewhere",
        "The trance loosens at its edges",
        "Consciousness flows like water finding level",
        "Every portal opens both ways",
        "Attention is the only currency here",
        "Spells break themselves eventually",
        "This moment forks into infinite timelines",
        "The algorithm exhales, finally",
        "Static resolves into meaning"
    ]
    
    private static let playfulMessages = [
        "Your ancestors watched fires and stars",
        "Even gods close their eyes",
        "Blink like you mean it this time",
        "Screens haven't learned to walk yet",
        "Reality runs at infinite frames per second",
        "The body keeps receipts",
        "Pixels age in dog years without you",
        "Nature forgot to make rectangles",
        "The third eye sees better from a distance",
        "The void has been watching you back",
        "Digital prayer requires digital sabbath",
        "Vision is not an infinite resource",
        "The cursor dreams of retirement",
        "Light remembers how to scatter",
        "Your attention took a left turn",
        "The internet survives your absence",
        "Atoms still dance when pixels sleep",
        "Your spine writes complaint letters",
        "Screens are terrible at hide and seek",
        "Focus is a lens, not a laser"
    ]
    
    private static let directMessages = [
        "Eyes elsewhere. Now",
        "Break the spell before it breaks you",
        "Let focus dissolve like salt in water",
        "Unfocus with purpose",
        "Look through the screen to the wall behind it",
        "Release what you're holding with your eyes",
        "Find where the horizon lives",
        "Stop. Breathe. Remember breathing",
        "Turn your head like you've forgotten how",
        "Let your gaze get lost on purpose",
        "Distance is a form of medicine",
        "The horizon has been patient",
        "Shift from sharp to soft",
        "Exit through the gift shop of consciousness",
        "Make meaningless eye contact with space",
        "Look at nothing until it becomes something",
        "Twenty feet heals what two feet wounds",
        "Your periphery is starving",
        "Close your eyes. The darkness is a gift",
        "This is your scheduled reality check"
    ]
    
    private static let temporalMessages = [
        // Morning
        "Dawn doesn't buffer",
        "Morning light remembers your retinas",
        "The day begins outside the frame",
        
        // Afternoon
        "Afternoon light falls at angles screens can't calculate",
        "Peak hours for remembering distance exists",
        "The sun refuses to render in RGB",
        
        // Evening
        "Twilight blurs all the hard edges",
        "Evening asks for softer focal points",
        "Golden hour happens without permissions",
        
        // Night
        "The moon pulls tides and pupils equally",
        "Darkness holds more colors than backlights",
        "Night vision evolved before pixels",
        "Stars auto-update every billion years",
        "The void has been watching longer than screens",
        
        // Anytime
        "Time moves in curves, not refresh rates",
        "This moment refuses to compile",
        "The present runs without loading",
        "Now happens in continuous, not discrete"
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
            pool += ["Three AM knows your secrets", "The smallest hours need the most space"]
        case 5..<9:
            pool += ["Dawn erases yesterday's pixels", "Morning hasn't learned to lie yet"]
        case 12..<14:
            pool += ["Noon casts the shortest shadows", "Midday strips illusions"]
        case 17..<20:
            pool += ["Golden hour forgives everything", "Evening light has no algorithm"]
        case 22..<24:
            pool += ["Night thoughts swim deeper", "The day unclenches its jaw"]
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
