# 🔮 Spellbreak - Project Guide

## Overview
Spellbreak is a mystical break reminder app for macOS that creates immersive, unskippable (but skippable with friction) break experiences.

**Domain**: spellbreak.app  
**Philosophy**: "Break the spell! You're not being productive, you're being hypnotized"  
**Status**: 75% ready - Awaiting Developer ID for App Store submission

## Technical Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Minimum**: macOS 13+
- **Build**: Swift Package Manager

## Architecture

### Core Components
- `SpellbreakApp.swift` - Main app entry, menu bar management, break tracking
- `OverlayWindow.swift` - Full-screen break overlay with hold-to-skip
- `SpellTextGenerator.swift` - NY tarot reader message system
- `AuroraBackground.swift` - Animated wave effects (Canvas + TimelineView)
- `PreferencesView.swift` - Settings interface (Time/Vibes tabs)
- `SoundManager.swift` - Audio playback for chimes and ambient
- `MenuViewSimple.swift` - Menu bar UI with countdown

### Message System (NY Tarot Reader Voice)
- **Grammar**: Body parts as witnesses, patterns as entities
- **Format**: 5-6 word maximum per message
- **Examples**: 
  - "Your shoulders holding court since Tuesday"
  - "The trance gets comfortable"
  - "Screen's got your number"
- **Distribution**: 60% NY voice, 40% mystical/temporal variety

### Visual System
- **Desktop blur**: ultraThickMaterial for frosted glass effect
- **Aurora waves**: Flowing gradients with 30px blur
- **Themes**: Aurora (default), Cosmic, Lava
- **Palettes**: Time-based (dawn/day/evening/night)
- **Text**: Soft glow with multiple shadows, 1.2s fade-in
- **Particles**: Ambient floating orbs

## Key Features

### Hold-to-Skip Mechanism
- Duration = 1 second per break minute
- Clamped between 2-15 seconds
- Visual ring progress indicator
- Shows percentage while holding
- Requires commitment to skip

### Time-Based Palettes
- **Dawn** (5-10am): Rose gold, dusty rose
- **Day** (10-5pm): Golden, coral, magenta
- **Evening** (5-9pm): Sunset orange, hot pink
- **Night** (9pm-5am): Electric purple, deep violet

## Build & Run

```bash
# Development
./run.sh

# Production build
./build-app.sh

# Clean build
swift package clean
swift build -c release

# Open built app
open /Users/pabloalvarado/Projects/active/mac/spellbreak/build/Spellbreak.app
```

## App Store Preparation

### ✅ Completed
- Privacy policy (zero data collection)
- App Store description 
- Entitlements configuration
- Assets.xcassets structure
- Code signing guide

### ❌ Needed
- Apple Developer ID ($99/year)
- App icon images (mystical crystal ball design)
- Screenshots (6 required)

### Files Created
- `PRIVACY.md` - Privacy policy
- `APP_STORE.md` - Store listing content
- `SIGNING_GUIDE.md` - Step-by-step signing instructions
- `Assets.xcassets/AppIcon.appiconset/` - Icon structure

## Performance Targets
- **CPU**: <20% Intel, <10% Apple Silicon
- **Memory**: +50-100MB max overhead
- **Frame rate**: Smooth 60fps animations

## App Store Requirements
- ✅ Sandboxed
- ✅ No network access
- ✅ No microphone usage
- ✅ Privacy-focused
- ✅ Proper entitlements
- ⏳ Developer ID needed
- ⏳ Notarization required

## Recent Updates
- Transformed messages to NY tarot reader voice (Jan 2025)
- Implemented 5-word message limit
- Added body/spirit/state awareness system
- Prepared complete App Store submission package

## Design Principles
- Street-smart occult wisdom, not new age mystical
- No corporate wellness vibes
- Friction should feel ritual-like, not punitive
- Messages that know your patterns before you do
- 80/20 approach - simple solutions over complexity

---

*"Your shoulders been holding court"* 🌙