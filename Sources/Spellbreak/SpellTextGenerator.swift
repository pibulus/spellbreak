//
//  SpellTextGenerator.swift
//  Spellbreak
//
//  Abstract, mystical break generator powered by combinatorial entropy.
//  Every line is an observation, not an instruction — nothing here ever tells
//  you to look, stretch, breathe, or do. It names what is already happening
//  and lets the body hear it.
//

import Foundation

struct SpellTextGenerator {

    // ===================================================================
    // ENTROPY INGREDIENTS - short, abstract, observational fragments
    // ===================================================================

    private static let bodyParts = [
        "Shoulders", "Jaw", "Spine", "Eyes", "Breath",
        "Palms", "Temples", "Collarbones", "Ribs", "Wrists",
        "Brow", "Throat", "Neck", "Pulse", "Edges",
        "Hands", "Chest", "Gaze", "Fingertips", "Posture"
    ]

    // States, not orders. "Softening" instead of "soft" — a process already
    // underway, not a job being handed out.
    private static let bodyStates = [
        "adrift", "unwinding", "floating", "settling", "loosening",
        "quiet", "dissolved", "wide", "resting", "spacious",
        "in orbit", "unspooling", "weightless", "open", "still",
        "grounded", "slack", "unhooked", "softening", "lightening"
    ]

    private static let ambientElements = [
        "Static", "Glass", "Geometry", "Horizon", "Room",
        "Periphery", "Frame", "Shadows", "Glow", "Light",
        "Signal", "Air", "Distance", "Depth", "Frequency",
        "Loop", "Gravity", "Angles", "Space", "Focus"
    ]

    private static let ambientStates = [
        "dissolving", "softening", "cooling", "fading", "drifting",
        "clearing", "opening", "slowing", "holding steady", "unlocked",
        "weightless", "in suspension", "unbound", "untangled", "silent",
        "humming", "easing", "settling", "going quiet"
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

    // Full sentences in the tarot-reader voice — things noticed, never things
    // ordered. These are the lines that already know what's going on.
    private static let observations = [
        "The trance gets comfortable",
        "The screen isn't watching back",
        "Something settles behind the eyes",
        "The shoulders let go a little",
        "A slow tide under the ribs",
        "The room was always this quiet",
        "Light pools at the edges",
        "The jaw unhooks itself",
        "Gravity eases off a notch",
        "The spine finds its old drift",
        "Time goes soft at the edges",
        "The day loosens its grip",
        "A low hum between the temples",
        "The frame forgets to hold",
        "The breath remembers its own pace",
        "Nothing here is asking",
        "The pulse drops a floor or two",
        "The edges of the room blur"
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
        // Mode 1 (30%): Body + State ("Shoulders adrift", "Jaw softening", "Spine in orbit")
        // Mode 2 (30%): Ambient + State ("Static cooling", "Frame dissolving", "Horizon wide open")
        // Mode 3 (20%): Abstract Mystical Spark ("Soft geometry", "Quiet frequency", "Pale static")
        // Mode 4 (20%): Full observation ("The trance gets comfortable")

        let roll = Int.random(in: 1...100)

        if roll <= 30 {
            let body = bodyParts.randomElement() ?? "Shoulders"
            let state = bodyStates.randomElement() ?? "adrift"
            return "\(body) \(state)"
        } else if roll <= 60 {
            let element = ambientElements.randomElement() ?? "Frame"
            let state = ambientStates.randomElement() ?? "dissolving"
            return "\(element) \(state)"
        } else if roll <= 80 {
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
        } else {
            var pool = observations

            if let lunar = moonSparks[getMoonPhase()] {
                pool += lunar
            }

            return pool.randomElement() ?? "The trance gets comfortable"
        }
    }
}
