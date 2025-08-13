# Eyedrop

A minimalist macOS menu bar app that reminds you to take regular breaks and rest your eyes.

## Features

- **20-20-20 Rule**: Customizable break reminders (default: every 20 minutes for 20 seconds)
- **Beautiful Break Overlay**: Full-screen break reminders with calming visuals
- **Ambient Music**: Optional relaxing background music during breaks
- **Lock Mode**: Option to make breaks mandatory (cannot be skipped)
- **Statistics Tracking**: Monitor your break completion rate
- **Menu Bar Integration**: Unobtrusive menu bar icon with quick controls

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/pibulus/eyedrop.git
cd eyedrop/Eyedrop
```

2. Build the app:
```bash
./build-app.sh
```

3. Run the app:
```bash
open Eyedrop.app
```

4. Optional: Move to Applications folder for permanent installation

## Usage

- Click the droplet icon in your menu bar to access controls
- Adjust break intervals and duration in Preferences
- Enable Lock Mode to prevent skipping breaks
- Choose from different visual styles for break screens
- View your break statistics to track eye care habits

## Development

Built with:
- Swift 5.9
- SwiftUI
- Swift Package Manager

### Building for Release

```bash
swift build -c release
./build-app.sh
```

### Code Signing for Distribution

The app includes proper entitlements for Mac App Store distribution. To sign for distribution:

```bash
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" Eyedrop.app
```

## Privacy

Eyedrop respects your privacy:
- No data collection or tracking
- All settings stored locally
- No network connections required
- Fully sandboxed for security

## License

Copyright © 2025 Pablo Alvarado. All rights reserved.

## Support

For issues or suggestions, please open an issue on GitHub.