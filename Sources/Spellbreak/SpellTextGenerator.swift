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
        "What if the void is waiting for you?",
        "Where do pixels go when they sleep?",
        "Can distance remember things?",
        "Maybe the spell wants to break",
        "Does reality buffer sometimes?",
        "What rhythm did your pulse forget?",
        "Do screens dream?",
        "Is infinity hiding in your periphery?",
        "Where does time go between frames?",
        "What if simulations need rest too?",
        "Something flickers at the edge",
        "Your attention might be needed elsewhere",
        "The trance seems looser here",
        "Water always finds its level",
        "Every door swings both ways",
        "What currency do you pay in?",
        "Spells might break themselves",
        "This moment could fork",
        "The algorithm might be tired",
        "Static might mean something"
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
        "eyes", "hands", "breath", "pulse", "mind",
        "horizon", "distance", "spell", "trance", "focus",
        "light", "shadow", "void", "edge", "threshold"
    ]
    
    private static let questions = [
        "What do [symbol] know that screens don't?",
        "Where do [symbol] go when you're not looking?",
        "Can [symbol] exist without pixels?",
        "Do [symbol] remember how to rest?",
        "What if [symbol] need something else?",
        "How long have [symbol] been waiting?",
        "When did [symbol] last feel real?",
        "Why do [symbol] pull away?",
        "Could [symbol] be trying to tell you something?",
        "What happens when [symbol] disconnect?"
    ]
    
    private static let suggestions = [
        "Maybe [symbol] want distance",
        "Perhaps [symbol] know better",
        "[symbol] might be ready",
        "[symbol] could use a break",
        "Consider what [symbol] need",
        "[symbol] seem restless",
        "Notice how [symbol] drift",
        "[symbol] appear different here",
        "Something about [symbol] shifts",
        "[symbol] might remember"
    ]
    
    private static let observations = [
        "[symbol] behave differently at this hour",
        "[symbol] and screens rarely agree",
        "[symbol] existed before pixels",
        "[symbol] don't render properly",
        "[symbol] cast interesting shadows",
        "[symbol] move in analog time",
        "[symbol] have their own rhythm",
        "[symbol] know things",
        "[symbol] aren't digital",
        "[symbol] follow older rules"
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
        
        // 40% chance to use symbol-based generation
        let useSymbols = Int.random(in: 1...10) <= 4
        
        if useSymbols {
            // Generate a symbol-based message
            if let symbol = symbols.randomElement() {
                let templateType = Int.random(in: 1...3)
                let template: String
                
                switch templateType {
                case 1:
                    template = questions.randomElement() ?? "What do [symbol] know?"
                case 2:
                    template = suggestions.randomElement() ?? "Maybe [symbol] need space"
                default:
                    template = observations.randomElement() ?? "[symbol] exist elsewhere"
                }
                
                // Capitalize first letter of symbol if it starts the sentence
                let message = template.replacingOccurrences(of: "[symbol]", with: symbol)
                if message.first == symbol.first {
                    return message.prefix(1).uppercased() + message.dropFirst()
                }
                return message
            }
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
