# Privacy Policy for Spellbreak

*Last updated: November 5, 2026*

## Data Collection

Spellbreak collects zero data.

- No analytics, tracking, telemetry, or crash reporting
- No network requests (the app carries no network entitlement)
- No accounts or cloud storage
- No camera access
- No audio recording or microphone capture

## Local Activity Checks

When **Pause while busy** is enabled, Spellbreak reads local macOS system state so a break waits out calls, presentations, drags, and active typing:

- **Microphone running state**: queries Core Audio (`kAudioDevicePropertyDeviceIsRunningSomewhere`) on the default input device. Core Audio returns a boolean flag only; audio is never captured, read, or requested, and macOS never prompts for microphone permission.
- **Fullscreen windows**: reads window bounds reported by macOS to detect full-screen spaces or borderless windows, without reading window titles or screen contents.
- **Display-sleep assertions**: queries IOKit (`IOPMCopyAssertionsByProcess` and `IOPMCopyAssertionsStatus`) to detect active video playback or screen sharing.
- **Input timing**: queries Quartz (`CGEventSource.secondsSinceLastEventType`) for elapsed seconds since the last keystroke and current mouse-button state. Only the elapsed-seconds counter and boolean button flag are read; keystrokes and screen contents are never inspected.

Turning **Pause while busy** off in Settings stops those deferral checks.

To count time away from the Mac as a completed break, Spellbreak also checks total input idle seconds via `CGEventSource` alongside `IOPMCopyAssertionsStatus` display-awake state. Both values stay in memory and are discarded immediately.

## Local Storage

Settings stay in standard macOS `UserDefaults` inside the app container and never leave the Mac:

- Timing preferences (`breakIntervalMin`, `breakDurationSec`, `lockMode`, `deferDuringFullscreen`)
- Visual, audio, and message preferences (`visualTheme`, `showBreakMessage`, `musicEnabled`, `soundEffectsEnabled`)
- Session continuity keys (`hasLaunchedBefore`, `timerWasRunning`, `lastBreakTimestamp`)
- Recently displayed break lines (`recentBreakMessages`, `recentNoticingMessages`) so lines do not repeat immediately

## System Permissions

Spellbreak requires no macOS privacy permissions. **Launch at Login** uses `SMAppService` and remains off until enabled in Settings.

## Purchases

- **Mac App Store build**: the 7-day trial and one-time unlock are non-consumable In-App Purchases processed by Apple via StoreKit. Spellbreak reads local entitlement state only and never sees payment details or Apple Account credentials.
- **Direct notarized build**: runs unlocked with no license server, receipt check, or payment record on the Mac.

## Website

The Spellbreak app makes zero network connections. Separately, the website at `spellbreak.app` counts aggregate page views on self-hosted hardware without cookies, ad trackers, or personal profiles.

## Contact

Privacy questions: pibulus@gmail.com

## Updates

Material changes to this policy will update the date at the top of this page.
