# Spellbreak - Code Glossary

Quick reference for Spellbreak's break reminder architecture.

## Views (SwiftUI)

**OverlayWindow** - Full-screen break overlay with animations
`Sources/Spellbreak/OverlayWindow.swift` - Main break UI

**PreferencesView** - Settings with Time/Vibes tabs
`Sources/Spellbreak/PreferencesView.swift` - Break interval, duration, theme config

**MenuViewSimple** - Menu bar popover
`Sources/Spellbreak/MenuViewSimple.swift` - Timer status, stats, quick actions

## Background Components

**AuroraBackground** - Flowing gradient waves
`Sources/Spellbreak/AuroraBackground.swift` - Canvas + TimelineView animation, palette-driven

**AuroraPalette** - The colour a break wears
`Sources/Spellbreak/AuroraBackground.swift` - `.time` (hour-aware), `.ember` (warm), `.violet` (cool)

**AmbientParticles** - Floating orbs overlay
`Sources/Spellbreak/AmbientParticles.swift` - Subtle particle system, palette-matched

## App Structure

**SpellbreakApp** - Main app entry (@main)
`Sources/Spellbreak/SpellbreakApp.swift` - Settings scene only

**AppDelegate** - Menu bar management
`Sources/Spellbreak/SpellbreakApp.swift` - Status item, break coordination

**AppState** - Main state manager (ObservableObject)
`Sources/Spellbreak/SpellbreakApp.swift` - Timer, stats, overlay control

**StatusBarController** - Menu bar item controller
`Sources/Spellbreak/StatusBarController.swift` - Icon, popover coordination

## Services & Utilities

**SpellTextGenerator** - NY tarot reader message system
`Sources/Spellbreak/SpellTextGenerator.swift` - Break messages (5-6 word max)

**SoundManager** - Audio playback (chimes, ambient)
`Sources/Spellbreak/SoundManager.swift` - AVAudioPlayer management

**OverlayWindowController** - Full-screen window wrapper
`Sources/Spellbreak/SpellbreakApp.swift` - NSWindowController for overlay

**TransparentHostingView** - Fix white background in NSHostingView
`Sources/Spellbreak/SpellbreakApp.swift` - Transparent SwiftUI hosting

## UI Elements

**ToggleRow** - Full-width toggle row inside a shared card
`Sources/Spellbreak/PreferencesView.swift` - Stacks into one calm behaviour list

## Core Concepts

**Message System** - Observational, never instructional
- Grammar: Body parts as witnesses, patterns as entities
- Format: 5-6 word maximum per message
- Distribution: 30% body, 30% ambient, 20% mystical spark, 20% full observation
- Example: "The trance gets comfortable"
- Optional: `showBreakMessage` toggle hides the line entirely

**Hold-to-Skip Mechanism**
- Duration scales with break length
- Clamped between 2-15 seconds
- Visual ring progress indicator
- Shows percentage while holding

**Time-Based Palettes**
- Dawn (5-10am): Rose gold, dusty rose
- Day (10-5pm): Golden, coral, magenta
- Evening (5-9pm): Sunset orange, hot pink
- Night (9pm-5am): Electric purple, deep violet

**Visual Themes**
- Aurora: hour-aware, shifts with the clock
- Ember: always-warm dusk colours
- Violet: always-cool night colours
- Surprise: rolls one of the three each break

**Break Statistics** - Tracked per session + lifetime
- Completed breaks (today + total)
- Skipped breaks (today + total)
- Daily reset at midnight
- Persisted in @AppStorage

**Privacy Boundary** - Local-only behavior
- No network requests, accounts, analytics, or telemetry
- No camera or microphone probing
- Manual pause and heads-up notifications cover awkward timing
