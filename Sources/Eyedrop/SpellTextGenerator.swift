//
//  SpellTextGenerator.swift
//  Spellbreak
//
//  Generates mystical break messages based on time and moon phases.
//

import Foundation

struct SpellTextGenerator {
    private static let messages = [
        "Break the spell",
        "Look away",
        "Rest your eyes", 
        "Breathe deeply",
        "Stretch gently",
        "Blink slowly",
        "Focus far away",
        "Release the screen"
    ]
    
    private static let spells = [
        "Digital Unbinding",
        "Screen Release",
        "Pixel Liberation",
        "Focus Restoration",
        "Vision Renewal"
    ]
    
    static func generateMessage() -> String {
        messages.randomElement() ?? "Break the spell"
    }
    
    static func generateSpellName() -> String {
        spells.randomElement() ?? "Digital Unbinding"
    }
}
