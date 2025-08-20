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
        "what if the void is also waiting",
        "pixels, sleeping",
        "distance remembers",
        "spells want to break",
        "reality buffers here",
        "forgotten rhythms",
        "screens dreaming",
        "infinity in periphery",
        "time between frames",
        "simulations resting",
        "something at the edge",
        "attention, elsewhere",
        "looser here",
        "water finding level",
        "doors, both ways",
        "what currency",
        "self-breaking spells",
        "this moment, forking",
        "tired algorithms",
        "static as signal"
    ]
    
    private static let playfulMessages = [
        "What did your ancestors watch instead?",
        "Do even gods need to blink?",
        "What if you blinked with intention?",
        "Have screens learned to follow you yet?",
        "How many frames per second is reality?",
        "Does the body keep score?",
        "How do pixels age without you?",
        "Why didn't nature make rectangles?",
        "Can the third eye see from here?",
        "Has the void been watching back?",
        "What's the opposite of screen time?",
        "Is vision a renewable resource?",
        "What does the cursor dream of?",
        "Does light remember how to scatter?",
        "Where did your attention wander?",
        "Does the internet notice you're gone?",
        "Do atoms dance when nobody's watching?",
        "Is your spine trying to tell you something?",
        "Could you hide from your screen?",
        "Is focus more like water or light?"
    ]
    
    private static let directMessages = [
        "Try looking elsewhere",
        "Consider breaking free",
        "Let focus dissolve",
        "Maybe unfocus now",
        "Look through, not at",
        "Release your gaze",
        "Find the horizon",
        "Remember to breathe",
        "Turn away gently",
        "Let your eyes wander",
        "Distance might help",
        "The horizon waits",
        "Shift to soft focus",
        "Time to drift away",
        "Make space with your eyes",
        "Look at nothing specific",
        "Twenty feet away",
        "Notice the periphery",
        "Close your eyes briefly",
        "Consider this a reminder"
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
    // SYMBOL-BASED MESSAGE SYSTEM
    // ===================================================================
    
    private static let symbols = [
        "eyes", "hands", "breath", "pulse", "thoughts",
        "horizons", "distance", "patterns", "rhythms", "focus",
        "light", "shadows", "edges", "thresholds", "signals",
        "attention", "memory", "stillness", "motion", "time"
    ]
    
    private static let fragments = [
        "[symbol] might be [verb]",
        "something about [symbol]",
        "[symbol] or [symbol2]?",
        "the way [symbol] [verb]",
        "between [symbol] and [symbol2]",
        "[symbol], but [verb]",
        "if [symbol] could [verb]",
        "[symbol] without [symbol2]",
        "where [symbol] [verb]",
        "[symbol] becoming [symbol2]"
    ]
    
    private static let verbs = [
        "waiting", "shifting", "remembering", "dissolving",
        "gathering", "escaping", "returning", "listening",
        "opening", "closing", "breathing", "dreaming",
        "searching", "finding", "losing", "becoming"
    ]
    
    private static let questions = [
        "what if [symbol] [verb]?",
        "do [symbol] ever [verb]?",
        "when [symbol] [verb], what happens?",
        "how do [symbol] know when to [verb]?",
        "can [symbol] [verb] without you?",
        "why do [symbol] [verb] here?",
        "where do [symbol] go to [verb]?",
        "who taught [symbol] to [verb]?"
    ]
    
    private static let whispers = [
        "[symbol]...",
        "...and [symbol]",
        "[symbol]?",
        "([symbol])",
        "[symbol] → [symbol2]",
        "[symbol] / [symbol2]",
        "[symbol]. [symbol2].",
        "[symbol] & [symbol2] &",
        "–[symbol]–",
        "[symbol]:[symbol2]"
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
        
        // 50% chance to use symbol-based generation for more emergent meaning
        let useSymbols = Int.random(in: 1...10) <= 5
        
        if useSymbols {
            // Generate a symbol-based message
            let symbol1 = symbols.randomElement() ?? "distance"
            let symbol2 = symbols.randomElement() ?? "time"
            let verb = verbs.randomElement() ?? "waiting"
            
            let templateType = Int.random(in: 1...10)
            var template: String
            
            switch templateType {
            case 1...3:  // 30% - Fragments (most abstract)
                template = fragments.randomElement() ?? "[symbol] might be [verb]"
            case 4...6:  // 30% - Questions
                template = questions.randomElement() ?? "what if [symbol] [verb]?"
            case 7...8:  // 20% - Whispers (minimal)
                template = whispers.randomElement() ?? "[symbol]..."
            default:     // 20% - Simple symbol
                return symbol1  // Just the word alone
            }
            
            // Replace placeholders
            template = template.replacingOccurrences(of: "[symbol2]", with: symbol2)
            template = template.replacingOccurrences(of: "[symbol]", with: symbol1)
            template = template.replacingOccurrences(of: "[verb]", with: verb)
            
            // Capitalize first letter if needed
            if let first = template.first, first.isLowercase {
                return template.prefix(1).uppercased() + template.dropFirst()
            }
            return template
        }
        
        // Otherwise use regular pool selection
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
        
        // Time-based emergent fragments
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5:
            pool += ["3am knows", "smallest hours", "deep time", "thoughts pooling"]
        case 5..<9:
            pool += ["dawn erasing", "morning's honesty", "light returning", "pixels fading"]
        case 12..<14:
            pool += ["noon shadow", "peak light", "center holding", "day's middle"]
        case 17..<20:
            pool += ["golden forgiveness", "evening algorithm", "light softening", "edges blurring"]
        case 22..<24:
            pool += ["night swimming", "day releasing", "darkness opening", "time slowing"]
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
