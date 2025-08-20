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
    // NY TAROT READER MESSAGE SYSTEM - Street-smart occult wisdom
    // ===================================================================
    
    // Body parts as witnesses who've seen things
    private static let bodyParts = [
        "Your shoulders", "Your jaw", "Your neck", "Your spine",
        "Your eyes", "Your hands", "Your breathing", "Your chest",
        "That spot between your eyes", "Your lower back", "Your edges"
    ]
    
    // What body parts do (shorter actions for 5-6 word limit)
    private static let bodyActions = [
        "holding court", "keeping score", "telling stories",
        "carrying weight", "collecting receipts", "taking notes",
        "running hot", "getting loud", "speaking up"
    ]
    
    // Shorter time markers
    private static let timeMarkers = [
        "since Tuesday", "since breakfast", "all morning",
        "for hours", "too long", "a while"
    ]
    
    // The patterns/states as entities
    private static let patterns = [
        "The trance", "The loop", "The grip", "The spell",
        "That old story", "The usual spiral", "The same dance",
        "The pull", "The static", "The hold", "The drift"
    ]
    
    // Pattern behaviors
    private static let patternActions = [
        "gets comfortable", "knows your name", "feeds itself",
        "grows stronger", "likes the dark", "needs your permission",
        "recognizes you", "settles in", "makes itself at home",
        "gets cozy", "knows you're here"
    ]
    
    // Direct address openers
    private static let openers = [
        "Listen,", "Real talk:", "Here's the thing:",
        "Check this:", "Tell me something:", "Question:",
        "Notice how", "Funny thing is", "You know what?"
    ]
    
    // Knowing questions (5-6 words max)
    private static let knowingQuestions = [
        "How long you carrying that?",
        "This feeling familiar?",
        "Your spine straight or storytelling?",
        "That tension got a name?",
        "Where's this headed?",
        "Same movie, different day?",
        "The grip getting tighter?",
        "You feeding the trance?",
        "When'd you last move?",
        "Your breathing shallow?",
        "Shoulders up by your ears?",
        "The loop feel cozy?",
        "Screen winning this round?",
        "Your body keeping score?"
    ]
    
    // Practical wisdom statements (5-6 words max)
    private static let wisdomStatements = [
        "Screens don't blink first",
        "Pixels can't touch back",
        "The spell needs permission",
        "Hypnosis needs your yes",
        "Bodies keep better time",
        "Tension's just stored fear",
        "The loop needs you",
        "Distance shrinks the screen",
        "Ancestors didn't watch rectangles",
        "The trance breaks easy"
    ]
    
    // Check-in questions (5 words max)
    private static let checkIns = [
        "Where you at?",
        "You still there?",
        "Body talking yet?",
        "Feel that shift?",
        "Notice anything?",
        "You tracking this?",
        "Getting the picture?",
        "Catching the pattern?",
        "See what's happening?",
        "Feeling the pull?"
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
        
        // 60% chance to use NY tarot reader voice
        let useNYVoice = Int.random(in: 1...10) <= 6
        
        if useNYVoice {
            let messageType = Int.random(in: 1...6)
            
            switch messageType {
            case 1:  // Body + Action (4-5 words)
                let body = bodyParts.randomElement() ?? "Your shoulders"
                let action = bodyActions.randomElement() ?? "holding court"
                // 50% chance to add time for 5-6 words total
                if Int.random(in: 1...2) == 1 {
                    let time = timeMarkers.randomElement() ?? "too long"
                    return "\(body) \(action) \(time)"
                } else {
                    return "\(body) been \(action)"
                }
                
            case 2:  // Pattern + Action (3-4 words)
                let pattern = patterns.randomElement() ?? "The trance"
                let action = patternActions.randomElement() ?? "gets comfortable"
                return "\(pattern) \(action)"
                
            case 3:  // Direct knowing question (3-5 words)
                return knowingQuestions.randomElement() ?? "This feeling familiar?"
                
            case 4:  // Just wisdom (4-5 words) - no opener to keep it short
                let wisdom = wisdomStatements.randomElement() ?? "Screens don't blink first"
                return wisdom
                
            case 5:  // Simple check-in (3-4 words)
                return checkIns.randomElement() ?? "You still there?"
                
            default:  // Short body observations (4-5 words)
                let body = bodyParts.randomElement() ?? "Your breathing"
                let shortObservations = [
                    "\(body) trying to talk?",
                    "\(body) got something?",
                    "\(body) sending signals?",
                    "\(body) speaking up?",
                    "Notice \(body.lowercased())?"
                ]
                return shortObservations.randomElement() ?? "\(body) trying to talk?"
            }
        }
        
        // 40% chance for other mystical/temporal messages
        var pool: [String] = []
        
        // Mix in some of the original messages for variety
        let mixType = Int.random(in: 1...3)
        switch mixType {
        case 1:
            pool = mysticalMessages.shuffled().prefix(10).map { $0 }
        case 2:
            pool = playfulMessages.shuffled().prefix(10).map { $0 }
        default:
            pool = directMessages.shuffled().prefix(10).map { $0 }
        }
        
        // Context-aware additions
        
        // If been too long (>40 mins), add direct NY voice (5 words max)
        if let interval = lastBreakInterval, interval > 2400 {
            pool += [
                "It's been a minute",
                "You're in deep",
                "The grip's got you",
                "Your spine's writing novels"
            ]
        }
        
        // If many breaks skipped, get more knowing (5 words max)
        if skippedCount > 3 {
            pool += [
                "Same pattern, different day",
                "The loop knows you",
                "Screen's got your number",
                "This dance getting old?"
            ]
        }
        
        // Time-based NY observations (5 words max)
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5:
            pool += [
                "3am screens hit different",
                "Eyes running on fumes"
            ]
        case 5..<9:
            pool += [
                "Morning eyes need light",
                "Dawn's trying to help"
            ]
        case 12..<14:
            pool += [
                "Noon glare's got opinions",
                "Midday trance runs deep"
            ]
        case 17..<20:
            pool += [
                "Golden hour can't reach",
                "Evening's calling you back"
            ]
        case 22..<24:
            pool += [
                "Night eyes need mercy",
                "Screen knows you're tired"
            ]
        default:
            break
        }
        
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
