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

**AuroraBackground** - Flowing gradient waves (default theme)
`Sources/Spellbreak/AuroraBackground.swift` - Canvas + TimelineView animation

**CosmicBackground** - Starfield space theme
`Sources/Spellbreak/CosmicBackground.swift` - Particle-based cosmic effect

**LavaLampBackground** - Organic blob movements
`Sources/Spellbreak/LavaLampBackground.swift` - Blob animation theme

**AmbientParticles** - Floating orbs overlay
`Sources/Spellbreak/AmbientParticles.swift` - Subtle particle system

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

**HeartEyesIcon** - Custom emoji icon
`Sources/Spellbreak/HeartEyesIcon.swift` - 😍 glyph component

## Core Concepts

**Message System** - NY tarot reader voice
- Grammar: Body parts as witnesses, patterns as entities
- Format: 5-6 word maximum per message
- Distribution: 60% NY voice, 40% mystical/temporal variety
- Examples: "Your shoulders holding court since Tuesday"

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
- Aurora (default): Flowing gradients, wave effects
- Cosmic: Starfield with particles
- Lava: Organic blob movements

**Break Statistics** - Tracked per session + lifetime
- Completed breaks (today + total)
- Skipped breaks (today + total)
- Daily reset at midnight
- Persisted in @AppStorage

**Privacy Boundary** - Local-only behavior
- No network requests, accounts, analytics, or telemetry
- No camera or microphone probing
- Manual pause and heads-up notifications cover awkward timing
