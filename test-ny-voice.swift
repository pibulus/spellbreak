#!/usr/bin/env swift

import Foundation

// Test harness for NY tarot reader voice
print("🔮 Testing NY Tarot Reader Voice Messages")
print("==========================================\n")

// Simulate the message generation
func testNYVoice() {
    // Body parts as witnesses
    let bodyParts = [
        "Your shoulders", "Your jaw", "Your neck", "Your spine",
        "Your eyes", "Your hands", "Your breathing", "Your chest"
    ]
    
    // Body actions
    let bodyActions = [
        "been holding court", "been keeping score", "been rehearsing disaster",
        "been telling stories", "been carrying grudges", "been practicing tension"
    ]
    
    // Time markers
    let timeMarkers = [
        "since Tuesday", "since breakfast", "for three screens now",
        "since the last full moon", "from two jobs ago", "all morning"
    ]
    
    // Patterns
    let patterns = [
        "The trance", "The loop", "The grip", "The spell",
        "That old story", "The usual spiral"
    ]
    
    // Pattern actions
    let patternActions = [
        "gets comfortable", "knows your name", "feeds itself",
        "grows stronger", "needs your permission"
    ]
    
    // Knowing questions
    let knowingQuestions = [
        "How long you gonna carry that?",
        "This feeling familiar?",
        "Your spine straight or storytelling?",
        "Same movie, different day?",
        "You feeding the trance or is it feeding you?"
    ]
    
    // Wisdom statements
    let wisdomStatements = [
        "Screens don't blink first",
        "Pixels can't touch you back",
        "The spell only works if you feed it",
        "Your body keeps better time than clocks",
        "Tension's just fear in storage"
    ]
    
    print("Sample Messages (NY Tarot Reader Voice):")
    print("-----------------------------------------")
    
    // Generate various message types
    for i in 1...15 {
        let messageType = Int.random(in: 1...5)
        var message = ""
        
        switch messageType {
        case 1:  // Body + Action + Time
            let body = bodyParts.randomElement()!
            let action = bodyActions.randomElement()!
            let time = timeMarkers.randomElement()!
            message = "\(body) \(action) \(time)"
            
        case 2:  // Pattern + Action
            let pattern = patterns.randomElement()!
            let action = patternActions.randomElement()!
            message = "\(pattern) \(action)"
            
        case 3:  // Knowing question
            message = knowingQuestions.randomElement()!
            
        case 4:  // Listen + Wisdom
            let wisdom = wisdomStatements.randomElement()!
            message = "Listen, \(wisdom.lowercased())"
            
        default:  // Body observation
            let body = bodyParts.randomElement()!
            message = "\(body) trying to tell you something?"
        }
        
        print("\(String(format: "%2d", i)). \(message)")
    }
    
    print("\n✨ Voice Check:")
    print("   ✓ Street-smart occult wisdom")
    print("   ✓ Body parts as witnesses with agency")
    print("   ✓ Time-specific references")
    print("   ✓ Patterns as living entities")
    print("   ✓ Direct but knowing tone")
}

testNYVoice()