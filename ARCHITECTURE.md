# Spellbreak Architecture

## Overview
Spellbreak is a mystical break reminder app that creates an immersive, unskippable break experience using SpriteKit-based visual effects and time/moon-aware aesthetics.

## Core Architecture Decisions

### Visual System: SpriteKit
- **Why**: GPU-accelerated fragment shaders for smooth organic effects
- **Alternative considered**: SwiftUI animations (too limited for fluid effects)
- **Implementation**: Single SKScene with custom GLSL shader for ooze effect

### Break Overlay: NSWindow at screenSaver level
- **Why**: Ensures overlay appears above all other windows
- **Alternative considered**: Regular window (could be hidden by other apps)
- **Implementation**: Transparent, borderless window with SpriteKit view

### Palette System: Time + Moon Phase
- **Why**: Creates natural variation without user configuration
- **Alternative considered**: Random palettes (less meaningful)
- **Implementation**: PaletteManager calculates current palette based on time/moon

### State Management: ObservableObject + AppStorage
- **Why**: SwiftUI-native state management with persistence
- **Alternative considered**: Core Data (overkill for simple settings)
- **Implementation**: AppState for runtime, AppStorage for persistence

## Component Structure

```
SpellbreakApp (Main App)
├── MenuView (Menu Bar)
│   └── HeartEyesIcon (Animated menu icon)
├── OverlayWindow (Break Screen)
│   ├── FlowScene (SpriteKit ooze effect)
│   │   ├── Fragment Shader (Domain-warped noise)
│   │   └── Wisps Layer (Floating orbs)
│   └── Message & Controls
└── PreferencesView (Settings)

Supporting Services:
├── PaletteManager (Color management)
├── SoundManager (Audio playback)
└── AppState (Central state)
```

## Data Flow

1. **Timer triggers break** → AppState.showingOverlay = true
2. **Overlay appears** → FlowScene renders with current palette
3. **User holds skip** → Progress tracked, skip after hold duration
4. **Break completes** → Stats updated, overlay dismissed

## Performance Optimizations

- **Shader complexity**: Limited to 4 octaves for 60fps on older hardware
- **Wisps**: Sprite-based, not particle system (more control, less overhead)
- **Frame rate**: Adaptive (60/120fps) with battery saver mode
- **Low power mode**: Reduces shader iterations and wisp count

## Future Considerations

### Anonymous Presence System
- WebSocket connection to simple Node server
- UUID-based identification (no auth)
- Wisps appear for other users taking breaks

### Press-and-Hold Skip
- 1 second hold per minute of break (2-15s range)
- Visual ring progress indicator
- Prevents accidental skips

### Spell Text Generation
- Deterministic based on global minute (YYYYMMDDHHmm seed)
- Different text banks for time periods
- Moon phase adds flavor variations

## Legacy Code to Remove

The following components are from the old "Eyedrop" design and should be removed:
- `AuroraBackground.swift` - Replaced by FlowScene shader
- `AmbientParticles.swift` - Replaced by FlowScene wisps
- `HyperDriftRitual.swift` - Replaced by FlowScene
- Old visual styles ("cozy", "dreamy", "minimal") - Replace with mystical themes

## Security & Privacy

- **No tracking**: No analytics, no user identification
- **Local only**: All settings stored locally
- **Optional presence**: Can be completely disabled
- **App Store ready**: Follows all Apple guidelines

## Build & Deploy

```bash
# Development
./run.sh              # Build and run locally

# Production
./build-app.sh        # Create release build
--sign "Developer ID" # For distribution outside App Store
```

## Dependencies

- **None**: Pure Swift/SwiftUI/SpriteKit, no external packages
- **macOS 13+**: Minimum deployment target
- **Swift 5.9+**: Language version