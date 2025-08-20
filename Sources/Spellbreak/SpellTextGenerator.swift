//
//  SpellTextGenerator.swift
//  Spellbreak
//
//  Generates mystical break messages based on time and moon phases.
//

import Foundation

struct SpellTextGenerator {
    
    // ===================================================================
    // MAIN MESSAGE CATEGORIES - Primary break messages with personality
    // ===================================================================
    
    private static let mysticalMessages = [
        "The pixels release their hold",
        "The screen's enchantment weakens",
        "Your eyes remember the horizon",
        "The digital trance dissolves",
        "Reality shimmers back into focus",
        "The code loosens its grip",
        "Your retinas taste freedom",
        "The monitor's spell unravels",
        "Photons scatter like startled birds",
        "The cursor releases you"
    ]
    
    private static let playfulMessages = [
        "Hey, your eyeballs called—they miss the real world",
        "Plot twist: There's a whole universe past your screen",
        "Your corneas are staging an intervention",
        "Congratulations! You've been temporarily fired from staring",
        "This is your vision speaking: We need to talk",
        "Breaking: Local human remembers they have a body",
        "Achievement unlocked: Voluntary screen abandonment",
        "The pixels will survive without you",
        "Time to give your retinas a little treat",
        "Your eyes are unionizing—demanding better conditions"
    ]
    
    private static let poeticMessages = [
        "Let your gaze drift like morning mist",
        "Find the soft focus of distant things",
        "Remember how shadows dance on walls",
        "Watch the light play without purpose",
        "Let geometry blur into suggestion",
        "Witness the world's quiet breathing",
        "Observe how stillness moves",
        "Notice the space between thoughts",
        "Feel how distance feels",
        "Let your vision become liquid"
    ]
    
    private static let directMessages = [
        "Look away now",
        "Gaze into the distance",
        "Find something far to focus on",
        "Rest your eyes on nothing",
        "Blink slowly and deliberately",
        "Let your focus go soft",
        "Turn away from the glow",
        "Give your eyes permission to wander",
        "Release the screen",
        "Stop. Look. Breathe."
    ]
    
    private static let gentleMessages = [
        "Your eyes deserve this moment",
        "Be kind to your vision",
        "A small gift for your retinas",
        "Your future self thanks you",
        "This pause is medicine",
        "Your eyes are not machines",
        "Honor your human limits",
        "Screens can wait—you cannot",
        "Your vision is irreplaceable",
        "Choose your eyes over the urgency"
    ]
    
    // ===================================================================
    // SUBTITLE MESSAGES - Secondary text for added flavor
    // ===================================================================
    
    private static let subtitles = [
        "20 seconds of freedom",
        "The spell weakens with distance",
        "Every blink is resistance",
        "Your eyes will thank you",
        "The pixels can wait",
        "Reality has better resolution",
        "This too shall pass",
        "A moment of liberation",
        "The screen isn't going anywhere",
        "But seriously, look away",
        "Trust the process",
        "It's not procrastination, it's preservation",
        "Your vision matters more than this task",
        "The work will still be there",
        "Distance makes the eyes grow stronger"
    ]
    
    // ===================================================================
    // TIME-BASED MESSAGES - Contextual based on time of day
    // ===================================================================
    
    private static let morningMessages = [
        "Morning eyes need morning light",
        "Start the day with distance",
        "Your eyes are still waking up",
        "Dawn deserves your attention",
        "The morning won't wait for you"
    ]
    
    private static let afternoonMessages = [
        "The afternoon glare is real",
        "Peak screen fatigue hours",
        "Your eyes have been at this for hours",
        "The day's halfway done—so are your eyes",
        "Afternoon eyes need afternoon skies"
    ]
    
    private static let eveningMessages = [
        "The golden hour isn't on your screen",
        "Evening eyes grow weary",
        "Sunset happens beyond the monitor",
        "Your eyes have earned their rest",
        "The day's last light calls"
    ]
    
    private static let nightMessages = [
        "Night shift for your actual eyes",
        "The darkness is gentler than this glow",
        "Midnight eyes need midnight rest",
        "The screen burns brightest at night",
        "Your circadian rhythm is screaming"
    ]
    
    // ===================================================================
    // BREAK COUNT MESSAGES - Gets more insistent with skipped breaks
    // ===================================================================
    
    private static let firstBreakMessages = [
        "Time for your first break",
        "Let's start this right",
        "Your first pause of the day"
    ]
    
    private static let skippedBreakMessages = [
        "You skipped the last one—don't skip this",
        "Your eyes are keeping score",
        "Second chance to do the right thing",
        "The spell grows stronger each time you skip",
        "Your retinas filed a formal complaint"
    ]
    
    private static let manyBreaksMessages = [
        "You're getting good at this",
        "Another victory over the screen",
        "Building healthy habits",
        "Your eyes appreciate the consistency",
        "Keep the momentum going"
    ]
    
    // ===================================================================
    // PUBLIC METHODS
    // ===================================================================
    
    static func generateMessage(
        breakCount: Int = 0,
        skippedCount: Int = 0,
        lastBreakInterval: TimeInterval? = nil
    ) -> (primary: String, subtitle: String?) {
        
        let hour = Calendar.current.component(.hour, from: Date())
        var possibleMessages: [String] = []
        
        // Add time-based messages
        switch hour {
        case 5..<10:
            possibleMessages += morningMessages
        case 10..<14:
            possibleMessages += afternoonMessages
        case 14..<20:
            possibleMessages += eveningMessages
        default:
            possibleMessages += nightMessages
        }
        
        // Add break-count based messages
        if breakCount == 0 {
            possibleMessages += firstBreakMessages
        } else if skippedCount > 0 {
            possibleMessages += skippedBreakMessages
        } else if breakCount > 5 {
            possibleMessages += manyBreaksMessages
        }
        
        // If it's been too long since last break (>40 mins), be more direct
        if let interval = lastBreakInterval, interval > 2400 {
            possibleMessages += directMessages
            possibleMessages += ["It's been too long", "Seriously, take this break", "No excuses this time"]
        }
        
        // Mix in personality categories
        let categories = [mysticalMessages, playfulMessages, poeticMessages, directMessages, gentleMessages]
        let selectedCategory = categories.randomElement() ?? mysticalMessages
        possibleMessages += selectedCategory
        
        // Select primary message
        let primary = possibleMessages.randomElement() ?? "Break the spell"
        
        // Maybe add a subtitle (70% chance)
        let subtitle = Int.random(in: 1...10) <= 7 ? subtitles.randomElement() : nil
        
        return (primary: primary, subtitle: subtitle)
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
