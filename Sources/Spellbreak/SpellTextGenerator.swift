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
    // NOTICING - lines that know how the session is going. They only enter
    // the draw when they're true, and they notice gently: no scolding, no
    // streak-shaming, just the room clocking what happened.
    // ===================================================================

    /// A few breaks skipped this session
    private static let skippedNotices = [
        "The last few got waved off",
        "The trance has been winning lately",
        "Some spells take a few goes",
        "The skips are piling up softly"
    ]

    /// Hours since a break was actually taken
    private static let longStretchNotices = [
        "A long stretch under the glass",
        "Hours since the last surfacing",
        "Time pooled while nobody looked"
    ]

    /// Breaks landing, none skipped
    private static let rhythmNotices = [
        "The rhythm is holding",
        "Another one, right on time",
        "The day has a pulse now"
    ]

    private static func notices(
        breakCount: Int,
        skippedCount: Int,
        lastBreakInterval: TimeInterval?
    ) -> [String] {
        if skippedCount >= 2 { return skippedNotices }
        if let interval = lastBreakInterval, interval >= 2 * 60 * 60 { return longStretchNotices }
        if breakCount >= 4 && skippedCount == 0 { return rhythmNotices }
        return []
    }

    // ===================================================================
    // MOON PHASE CALCULATION (approximate)
    // ===================================================================

    private static func getMoonPhase() -> String {
        let referenceNewMoon = Date(timeIntervalSince1970: 947182440)  // 2000-01-06 18:14 UTC
        let lunarCycleSeconds: TimeInterval = 29.53058867 * 86400
        let moonAgeSeconds = Date().timeIntervalSince(referenceNewMoon)
            .truncatingRemainder(dividingBy: lunarCycleSeconds)
        let moonAge = moonAgeSeconds / 86400

        // Full moon falls at day ~14.8 of the cycle; the old 18..<20 window lit up
        // "Full moon pull" four days after the actual full moon. New moon wraps the
        // end of the cycle as well as the start.
        switch moonAge {
        case ..<1.5, 28.0...: return "new"
        case ..<6.4: return "waxingCrescent"
        case ..<8.4: return "firstQuarter"
        case ..<13.8: return "waxingGibbous"
        case ..<15.8: return "full"
        case ..<21.1: return "waningGibbous"
        case ..<23.1: return "lastQuarter"
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
    // MEMORY - recently shown lines, kept on this Mac (UserDefaults), so the
    // same one doesn't come round again for days
    // ===================================================================

    private static let recentMessagesKey = "recentBreakMessages"
    /// Nothing repeats for ~2.5 working days at the default 20 minutes. Sized to the
    /// smallest pool: 18 observations drawn 20% of the time stay comfortably
    /// unexhausted, so the 30/30/20/20 mix holds. A longer memory starves them.
    private static let recentMessagesLimit = 60
    /// Noticing lines are few and only drawn when true, so they get a shorter memory
    /// of their own — still never the same thing twice in a day of breaks.
    private static let recentNoticesWindow = 24

    // ===================================================================
    // PUBLIC GENERATOR
    // ===================================================================

    static func generateMessage(
        breakCount: Int = 0,
        skippedCount: Int = 0,
        lastBreakInterval: TimeInterval? = nil
    ) -> String {
        let defaults = UserDefaults.standard
        var recent = defaults.stringArray(forKey: recentMessagesKey) ?? []
        let seen = Set(recent)
        let recentNotices = Set(recent.suffix(recentNoticesWindow))
        let noticing = notices(
            breakCount: breakCount,
            skippedCount: skippedCount,
            lastBreakInterval: lastBreakInterval
        ).filter { !recentNotices.contains($0) }

        let message: String
        if let notice = noticing.randomElement(), Int.random(in: 1...100) <= 35 {
            message = notice
        } else {
            // A mode whose whole pool was said lately re-rolls the mode. The memory is
            // sized so that's rare; if it somehow keeps happening, a repeat beats a
            // wordless break.
            var drawn: String?
            var attempts = 0
            while drawn == nil && attempts < 24 {
                drawn = drawLine(avoiding: seen)
                attempts += 1
            }
            message = drawn ?? drawLine(avoiding: []) ?? "The trance gets comfortable"
        }

        recent.append(message)
        if recent.count > recentMessagesLimit {
            recent.removeFirst(recent.count - recentMessagesLimit)
        }
        defaults.set(recent, forKey: recentMessagesKey)
        return message
    }

    /// One draw from the four modes, skipping anything in `seen`. Re-drawing inside
    /// the rolled mode (rather than re-rolling the mode) is what keeps the mix honest.
    /// Nil only when that mode's whole pool is in `seen`.
    private static func drawLine(avoiding seen: Set<String>) -> String? {
        // Mode 1 (30%): Body + State ("Shoulders adrift", "Jaw softening", "Spine in orbit")
        // Mode 2 (30%): Ambient + State ("Static cooling", "Frame dissolving", "Horizon wide open")
        // Mode 3 (20%): Abstract Mystical Spark ("Soft geometry", "Quiet frequency", "Pale static")
        // Mode 4 (20%): Full observation ("The trance gets comfortable")

        let roll = Int.random(in: 1...100)
        var pool: [String]

        if roll <= 30 {
            pool = bodyParts.flatMap { body in bodyStates.map { "\(body) \($0)" } }
        } else if roll <= 60 {
            pool = ambientElements.flatMap { element in ambientStates.map { "\(element) \($0)" } }
        } else if roll <= 80 {
            pool = mysticalSparks

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
        } else {
            pool = observations

            if let lunar = moonSparks[getMoonPhase()] {
                pool += lunar
            }
        }

        return pool.filter { !seen.contains($0) }.randomElement()
    }
}
