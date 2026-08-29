//
//  SpellTextGenerator.swift
//  Spellbreak
//
//  Abstract, mystical break generator powered by combinatorial entropy.
//

import Foundation

struct SpellTextGenerator {
    
    // ===================================================================
    // ENTROPY INGREDIENTS - Short, abstract, reflective fragments
    // ===================================================================
    
    private static let bodyParts = [
        "Shoulders", "Jaw", "Spine", "Retinas", "Breath",
        "Palms", "Temples", "Collarbones", "Ribs", "Wrists",
        "Brow", "Throat", "Neck", "Pulse", "Edges",
        "Hands", "Chest", "Gaze", "Fingertips", "Posture"
    ]
    
    private static let bodyStates = [
        "adrift", "unwinding", "soft", "floating", "cool",
        "loose", "quiet", "settling", "dissolved", "wide",
        "resting", "spacious", "in orbit", "unspooling", "weightless",
        "open", "still", "grounded", "breathing", "slack"
    ]
    
    private static let ambientElements = [
        "Static", "Glass", "Geometry", "Horizon", "Room",
        "Periphery", "Frame", "Shadows", "Glow", "Light",
        "Signal", "Air", "Distance", "Depth", "Frequency",
        "Loop", "Gravity", "Angles", "Space", "Focus"
    ]
    
    private static let ambientStates = [
        "dissolving", "softening", "cooling down", "fading", "drifting",
        "clearing", "rendered", "opening up", "wide open", "slowing down",
        "holding steady", "unlocked", "zero latency", "low frequency", "weightless",
        "in suspension", "unbound", "untangled", "silent"
    ]
    
    private static let mysticalSparks = [
        "Soft geometry",
        "Pale static",
        "Deep periphery",
        "Cool light",
        "Loose orbit",
        "Zero latency",
        "Quiet frequency",
        "Wide angle",
        "Open depth",
        "Subtle gravity",
        "Dusk settling",
        "Slow pulse",
        "Silent room",
        "Raw daylight",
        "Night air",
        "Empty buffer",
        "Past the frame",
        "Beyond the glass",
        "Unspooling",
        "Soft focus",
        "Full frame",
        "Clear distance",
        "Cold pixels",
        "Warm room",
        "Thin ice",
        "Easy drift",
        "Gentle slip"
    ]
    
    // ===================================================================
    // MOON PHASE CALCULATION (approximate)
    // ===================================================================
    
    private static func getMoonPhase() -> String {
        let referenceNewMoon = Date(timeIntervalSince1970: 947182440)
        let lunarCycleSeconds: TimeInterval = 29.53058867 * 86400
        let moonAgeSeconds = Date().timeIntervalSince(referenceNewMoon)
            .truncatingRemainder(dividingBy: lunarCycleSeconds)
        let moonAge = moonAgeSeconds / 86400
        
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
    // SPECIAL MOON SPARKS
    // ===================================================================
    
    private static let moonSparks = [
        "full": [
            "Full moon pull",
            "Lunar glow",
            "High tide"
        ],
        "new": [
            "New moon sky",
            "Deep dark",
            "Clear void"
        ]
    ]
    
    // ===================================================================
    // PUBLIC GENERATOR
    // ===================================================================
    
    static func generateMessage(
        breakCount: Int = 0,
        skippedCount: Int = 0,
        lastBreakInterval: TimeInterval? = nil
    ) -> String {
        // Mode 1 (35%): Body + State ("Shoulders adrift", "Jaw soft", "Spine in orbit")
        // Mode 2 (35%): Ambient + State ("Static cooling", "Frame dissolving", "Horizon wide open")
        // Mode 3 (30%): Abstract Mystical Spark ("Soft geometry", "Quiet frequency", "Pale static")
        
        let roll = Int.random(in: 1...100)
        
        if roll <= 35 {
            let body = bodyParts.randomElement() ?? "Shoulders"
            let state = bodyStates.randomElement() ?? "soft"
            return "\(body) \(state)"
        } else if roll <= 70 {
            let element = ambientElements.randomElement() ?? "Frame"
            let state = ambientStates.randomElement() ?? "dissolving"
            return "\(element) \(state)"
        } else {
            var pool = mysticalSparks
            
            // Contextual sparks
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 0..<5:
                pool += ["3am static", "Late glow", "Night drift"]
            case 5..<9:
                pool += ["Morning light", "Dawn horizon", "First rays"]
            case 12..<14:
                pool += ["Midday glare", "Sun overhead", "Raw light"]
            case 17..<20:
                pool += ["Golden hour", "Dusk settling", "Amber angle"]
            case 22..<24:
                pool += ["Night air", "Dark frame", "Low glow"]
            default:
                break
            }
            
            if let lunar = moonSparks[getMoonPhase()] {
                pool += lunar
            }
            
            return pool.randomElement() ?? "Soft focus"
        }
    }
}
