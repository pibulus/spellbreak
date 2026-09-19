# 🔮 Spellbreak

Break the digital spell. A mystical break-reminder for macOS that interrupts
screen trance with lush, full-screen rituals — just enough friction to make
skipping conscious, never punitive.

## Features

- **Aurora in four moods** — time-aware (shifts dawn → day → dusk → night),
  always-warm Ember, always-cool Violet, or Surprise Me (rolls one each break)
- **Observational messages** — never the same line twice, tuned to the hour and
  moon. They hint instead of ordering, and can be switched off entirely
- **Hold-to-skip** — a ring you hold for a beat; duration scales with break length
- **Heads-up countdown pill** — a gentle warning before the spell lands
- **Smart pauses** — waits out full-screen games, films, and presentations
- **Private by design** — no accounts, no tracking, no network requests, no camera
  or microphone access

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel

## Install

Download from [spellbreak.app](https://spellbreak.app), move it to
Applications, and launch.

## Build

```bash
./build-app.sh        # production build → build/Spellbreak.app
open build/Spellbreak.app
```

For a signed / notarized release, see [`SIGNING_GUIDE.md`](SIGNING_GUIDE.md).

## Project layout

```
Sources/Spellbreak/
├── SpellbreakApp.swift      # entry point, AppState, window controllers
├── OverlayWindow.swift      # full-screen break overlay
├── AuroraBackground.swift   # animated waves + AuroraPalette
├── AmbientParticles.swift   # floating orbs
├── SpellTextGenerator.swift # observational message engine
├── PreferencesView.swift    # Time / Vibes settings
├── MenuViewSimple.swift     # menu bar popover
├── StatusBarController.swift
├── SoundManager.swift
└── Utilities.swift          # palette, ScreenBusy heuristic
```

## Other docs

- [`APP_STORE.md`](APP_STORE.md) — store listing copy
- [`SIGNING_GUIDE.md`](SIGNING_GUIDE.md) — signing, notarization, distribution
- [`PRIVACY.md`](PRIVACY.md) — privacy policy
- [`GLOSSARY.md`](GLOSSARY.md) — code glossary

## License

Copyright © 2025–2026 Pablo Alvarado. All rights reserved.

## Support

[github.com/pibulus/spellbreak](https://github.com/pibulus/spellbreak)
