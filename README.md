# 🔮 Spellbreak

Break the digital spell! A mystical break reminder app for macOS that helps you maintain healthy screen time habits with beautiful, immersive break experiences.

## Features

- **Mystical Break Experience**: Full-screen overlay with flowing aurora waves and ambient particles
- **Smart Scheduling**: Customizable break intervals (default: every 20 minutes)
- **Hold-to-Skip**: Press and hold to skip if needed (duration scales with break length)
- **Time-Based Themes**: Color palettes shift with time of day (dawn, day, evening, night)
- **Ambient Soundscape**: Optional relaxing sounds during breaks
- **Menu Bar Control**: Unobtrusive icon with quick access to settings
- **Break Statistics**: Track your break completion rate

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

### Quick Start

1. Download the latest release from [spellbreak.app](https://spellbreak.app)
2. Move Spellbreak.app to your Applications folder
3. Launch and grant necessary permissions

### Build from Source

```bash
git clone https://github.com/pabloalvarado/spellbreak.git
cd spellbreak
./build-app.sh
open Spellbreak.app
```

## Usage

- **Menu Bar**: Click the Spellbreak icon to access controls
- **Preferences**: Customize break intervals, duration, and sounds
- **Skip Break**: Hold the skip button for 1 second per minute of break time
- **Pause/Resume**: Temporarily pause break reminders when needed

## Privacy & Security

Spellbreak respects your privacy:
- ✅ No data collection or analytics
- ✅ All settings stored locally
- ✅ No network connections
- ✅ Fully sandboxed
- ✅ No microphone access

## Development

Built with:
- Swift 5.9+
- SwiftUI
- Swift Package Manager

### Project Structure

```
Sources/Eyedrop/
├── SpellbreakApp.swift     # Main app entry point
├── OverlayWindow.swift     # Break overlay interface
├── AuroraBackground.swift  # Animated wave effects
├── PreferencesView.swift   # Settings interface
├── MenuViewSimple.swift    # Menu bar UI
└── SoundManager.swift      # Audio handling
```

### Code Signing

For Mac App Store distribution:

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  --entitlements Spellbreak.entitlements \
  Spellbreak.app
```

## License

Copyright © 2025 Pablo Alvarado. All rights reserved.

## Support

For issues or feature requests, visit [github.com/pabloalvarado/spellbreak](https://github.com/pabloalvarado/spellbreak)