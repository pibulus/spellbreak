# 🔮 Spellbreak - Project Guide

## Overview
Spellbreak is a mystical break reminder app for macOS that creates immersive, unskippable (but skippable with friction) break experiences.

**Domain**: spellbreak.app  
**Price**: $10  
**Philosophy**: "Break the spell! You're not being productive, you're being hypnotized"

## Technical Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Minimum**: macOS 13+
- **Build**: Swift Package Manager

## Architecture

### Core Components
- `SpellbreakApp.swift` - Main app entry, menu bar management
- `OverlayWindow.swift` - Full-screen break overlay
- `AuroraBackground.swift` - Animated wave effects (Canvas + TimelineView)
- `PreferencesView.swift` - Settings interface
- `SoundManager.swift` - Audio playback
- `MenuViewSimple.swift` - Menu bar UI

### Visual System
- **Desktop blur**: ultraThickMaterial for frosted glass effect
- **Aurora waves**: Flowing gradients with 30px blur
- **Palettes**: Time-based (dawn/day/evening/night)
- **Text**: Soft glow with multiple shadows
- **Particles**: Ambient floating orbs

## Key Features

### Hold-to-Skip Mechanism
- Duration = 1 second per break minute
- Clamped between 2-15 seconds
- Visual ring progress indicator
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
```

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

## Design Principles
- Lean into mystical but keep it soft
- No corporate wellness vibes
- Friction should feel ritual-like, not punitive
- 80/20 approach - simple solutions over complexity

---

*"Every 20 minutes, the enchantment must break"* 🌙