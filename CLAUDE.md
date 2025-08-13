# 🔮 Spellbreak - Break the Digital Spell

## Project Overview
Spellbreak (formerly Eyedrop) is a mystical break reminder app that creates immersive, unskippable breaks to free you from screen hypnosis. Built with SwiftUI + SpriteKit for macOS.

**Domain**: spellbreak.app (owned)
**Price Point**: $10
**Philosophy**: "Break the spell! Unskippable breaks set you free"

## Current Implementation Status

### ✅ Completed
- Renamed from Eyedrop to Spellbreak everywhere
- Canvas-based flowing wave animations (replaced broken SpriteKit)
- Warm gradient waves with heavy blur for dreamy effect
- Centered text layout with proper hierarchy
- Ambient particle system for atmosphere
- Clean SwiftUI-only overlay (no SpriteKit mixing)
- Time-of-day palettes (dawn/day/evening/night)
- Moon phase tint system

### 🚧 In Progress
- Press-and-hold skip mechanism (1s per minute, 2-15s range)
- Anonymous presence wisps (WebSocket-based)
- Spell text generation (deterministic by global minute)

### 📋 TODO
- Remove deprecated SwiftUI visual components
- Update settings UI for mystical themes
- Implement presence server (Node.js WebSocket)
- Add hold-to-skip ring UI
- Create spell text banks

## Technical Stack

### Core
- **Language**: Swift 5.9+
- **UI**: SwiftUI (interface) + SpriteKit (effects)
- **Minimum**: macOS 13+
- **Build**: Swift Package Manager

### Visual System
- **Shader**: GLSL fragment shader with domain-warped noise
- **Palettes**: 4 time periods × 8 moon phases = dynamic colors
- **Wisps**: Sprite-based floating orbs (not particle system)
- **Performance**: Adaptive frame rate, low power mode support

## Key Design Decisions

### Why SpriteKit over pure SwiftUI?
- Fragment shaders for buttery smooth organic effects
- GPU acceleration without Metal complexity
- Better performance for continuous animations

### Why time/moon-based palettes?
- Natural variation without configuration
- Everyone sees similar vibes at same time
- Mystical connection to natural cycles

### Why press-and-hold skip?
- Prevents accidental dismissal
- Creates friction that makes you think
- Visual feedback shows commitment to skipping

## Build & Run

```bash
# Development
./run.sh                    # Quick build and run

# Production build
./build-app.sh             # Create .app bundle
./build-app.sh --sign "Developer ID"  # For distribution

# Clean build
swift package clean
swift build -c release
```

## Project Structure

```
Spellbreak/
├── Sources/Eyedrop/        # Yes, still "Eyedrop" folder (hasn't been moved yet)
│   ├── SpellbreakApp.swift # Main app entry
│   ├── FlowScene.swift     # SpriteKit ooze effect ← MAIN VISUAL
│   ├── PaletteManager.swift # Time/moon colors
│   ├── OverlayWindow.swift # Break screen
│   ├── Constants.swift     # All magic numbers
│   └── [Deprecated]/       # Old SwiftUI effects to remove
├── ARCHITECTURE.md         # Design decisions
└── Package.swift          # SPM configuration
```

## Color Palettes

### Time of Day
- **Dawn** (5-10am): Rose, amber, peach - warm foggy morning
- **Day** (10-5pm): Peach, apricot, blush - soft high key
- **Evening** (5-9pm): Miami pink, violet, teal - sunset vibes  
- **Night** (9pm-5am): Deep violet, indigo, cyan - midnight city

### Moon Phase Modifiers
- New Moon: Cool cyan shift
- First Quarter: Gentle lavender
- Full Moon: Warm gold glow
- Last Quarter: Deep blue cast

## Performance Targets

- **Idle overlay**: <8ms/frame on 2020 MacBook Pro
- **CPU usage**: <20% Intel, <10% Apple Silicon
- **Memory**: +50-100MB max overhead
- **Thermal**: 60 FPS for 20min without fan on M1 Air

## Mystical Features (Planned)

### Anonymous Presence
- WebSocket to simple Node server
- UUID only, no accounts
- See wisps when others are breaking
- Completely optional, off by default

### Spell Text Generator
- Deterministic by minute (YYYYMMDDHHmm seed)
- Different banks: morning/afternoon/evening/night
- Moon phase adds flavor words
- Examples: "The trance lifts", "Reality beckons", "Break the binding"

### Press-and-Hold Friction
- Hold duration = 1s per break minute
- Clamped 2-15 seconds range
- Circular progress ring
- Release early = reset to zero

## Privacy & App Store

- **No tracking**: Zero analytics
- **Local only**: All settings in UserDefaults
- **Optional presence**: Can be fully disabled
- **No precise location**: Just time zone
- **No microphone**: Stated in Info.plist

## Voice Commands (If using voice mode)

```bash
# Quick commands
"Run spellbreak"
"Show me the overlay" 
"Test the break screen"
"Check the palette"
```

## Debug Commands

```bash
# See current palette colors
defaults read com.pabloalvarado.spellbreak

# Reset all settings
defaults delete com.pabloalvarado.spellbreak

# Force immediate break (for testing)
# (Run app and trigger via menu)
```

## Known Issues

1. **Shader uniforms**: Using u_palette1-4 instead of array (SpriteKit limitation)
2. **Mixed visual systems**: Old SwiftUI + new SpriteKit coexist
3. **Folder name**: Still in "Eyedrop" folder (needs migration)

## Pablo's Notes

- Lean into the mystical but keep it soft
- No corporate wellness vibes
- Ooze should feel like lava lamp meets mesh gradient
- Skip friction should feel ritual-like, not punitive
- "You're not being productive, you're being hypnotized"

## Lessons Learned (2024-08-12)

### What Works ✅
- **Canvas + TimelineView** for smooth 60fps flowing animations
- **Heavy blur (radius 10-42)** creates perfect dreamy diffuse effect
- **Warm gradients** (orange→pink→purple) match website aesthetic
- **Simple SwiftUI animations** outperform complex SpriteKit shaders
- **Centered VStack layout** with Spacers for proper text hierarchy

### What Doesn't Work ❌
- **SpriteKit uniforms on macOS** - ANY uniform causes white screen bug
- **SKAttribute** - API exists but doesn't work as documented
- **Mixed SpriteKit + SwiftUI** - Creates rendering conflicts
- **Static gradients** - Users want flowing, animated effects
- **HyperDriftRitual** - Created white blob artifacts

### Architecture Decisions 🏗️
- **showOverlayWindow()** in SpellbreakApp uses NSHostingView for SwiftUI
- **AuroraBackground** uses Canvas for wave drawing (not Shape/Path)
- **Multiple sine waves** create organic flow (base + 2 harmonics)
- **AmbientParticles** adds atmosphere without performance impact
- **Text hierarchy**: 48pt main → 32pt subtitle → 26pt countdown

### Technical Debt Cleaned ✨
- Removed broken FlowScene shader code
- Deleted HyperDriftRitual (white blob generator)
- Consolidated overlay to pure SwiftUI approach
- Fixed build script to use correct binary name

---

*"Every 20 minutes, the enchantment must break"* 🌙