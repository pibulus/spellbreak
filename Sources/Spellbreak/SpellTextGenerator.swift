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
        "What if screens need breaks too?",
        "Where do pixels go when you blink?",
        "Can distance help you think?",
        "Maybe the spell wants to break",
        "Does reality feel different at 20 feet?",
        "What rhythm did you have before this?",
        "Do screens know when you're gone?",
        "Is there something in your periphery?",
        "Where does your mind go between tasks?",
        "What if everything needs rest?",
        "Something's different at the edges",
        "Your attention might be split",
        "Things feel looser from here",
        "Everything finds its level",
        "Every door works both ways",
        "What are you paying with?",
        "Patterns break themselves eventually",
        "This moment could go anywhere",
        "The system might be tired too",
        "Background noise might be saying something"
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
    
    private static let bodySymbols = [
        "your eyes", "your hands", "your breath", "your shoulders", 
        "your neck", "your spine", "your feet", "your jaw"
    ]
    
    private static let sensationSymbols = [
        "tension", "distance", "focus", "rhythm", "stillness",
        "movement", "warmth", "weight", "space", "balance"
    ]
    
    private static let bodyQuestions = [
        "What are [symbol] trying to tell you?",
        "How do [symbol] feel right now?",
        "What do [symbol] need?",
        "Where are [symbol] holding stress?",
        "Can [symbol] relax from here?",
        "What would [symbol] do if they could?",
        "Notice what [symbol] are doing",
        "When did [symbol] last move?",
        "Are [symbol] comfortable?",
        "What position are [symbol] in?"
    ]
    
    private static let sensationQuestions = [
        "Where do you feel [symbol]?",
        "Is there [symbol] somewhere?",
        "Can you find [symbol]?",
        "What needs more [symbol]?",
        "How much [symbol] is enough?",
        "Notice the [symbol]",
        "Does [symbol] help?",
        "Where did the [symbol] go?",
        "Can you create [symbol]?",
        "What happens with more [symbol]?"
    ]
    
    private static let suggestions = [
        "Maybe check in with [symbol]",
        "Consider what [symbol] want",
        "[symbol] might need attention",
        "Notice [symbol]",
        "Let [symbol] guide you",
        "[symbol] know what to do",
        "Trust [symbol]",
        "Listen to [symbol]",
        "[symbol] have wisdom",
        "Follow what [symbol] suggest"
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
        
        // 40% chance to use symbol-based generation for body awareness
        let useSymbols = Int.random(in: 1...10) <= 4
        
        if useSymbols {
            let symbolType = Int.random(in: 1...3)
            var message: String
            
            switch symbolType {
            case 1:  // Body part questions
                let bodyPart = bodySymbols.randomElement() ?? "your eyes"
                let template = bodyQuestions.randomElement() ?? "How do [symbol] feel?"
                message = template.replacingOccurrences(of: "[symbol]", with: bodyPart)
                
            case 2:  // Sensation questions
                let sensation = sensationSymbols.randomElement() ?? "tension"
                let template = sensationQuestions.randomElement() ?? "Where do you feel [symbol]?"
                message = template.replacingOccurrences(of: "[symbol]", with: sensation)
                
            default:  // Suggestions
                let bodyPart = bodySymbols.randomElement() ?? "your breath"
                let template = suggestions.randomElement() ?? "Notice [symbol]"
                message = template.replacingOccurrences(of: "[symbol]", with: bodyPart)
            }
            
            return message
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
        
        // Time-based contextual messages
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5:
            pool += ["Late night eyes need different light", "3am thoughts need space"]
        case 5..<9:
            pool += ["Morning light helps reset", "Dawn changes how things look"]
        case 12..<14:
            pool += ["Midday glare is real", "Noon light shows everything"]
        case 17..<20:
            pool += ["Golden hour changes perspective", "Evening light is gentler"]
        case 22..<24:
            pool += ["Night screens hit different", "Time to wind down maybe"]
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
