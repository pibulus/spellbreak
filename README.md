# 🔮 Spellbreak

Break the digital spell. A mystical break-reminder for macOS that interrupts
screen trance with lush, full-screen rituals — just enough friction to make
skipping conscious, never punitive.

## Features

- **Aurora in four moods** — time-aware (shifts dawn → day → dusk → night),
  always-warm Ember, always-cool Violet, or Surprise (rolls a fresh harmonious
  palette each break)
- **Observational messages** — hundreds of lines, rarely the same one twice,
  tuned to the hour and moon, and they notice when you skip a few. They hint
  instead of ordering, and can be switched off entirely
- **Hold-to-skip** — a ring you hold for a beat; duration scales with break length
- **Lock mode** — the ring goes away and the break cannot be skipped, for the
  days where a way out is the whole problem
- **Heads-up countdown pill** — a gentle warning before the spell lands
- **Smart pauses** — waits out calls, full-screen games, films, presentations,
  and the end of your sentence; time away from the Mac counts as a break
- **Every display** — the break lands on the screen with your pointer; the others
  dim to match
- **Private by design** — no accounts, no tracking, no network requests, no camera,
  never records audio (it only checks whether the mic is busy)

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel

## Install

Download from [spellbreak.app](https://spellbreak.app), move it to Applications,
and launch. A$29 once, unlocked — no account, no trial timer, no subscription.

The Mac App Store build (free download, 7-day trial, one-time unlock) builds via
`./build-mas.sh` into `dist/Spellbreak-v<version>-mas.pkg` and is verified by
`./mas-check.sh`.

## Build

```bash
./build-app.sh        # production build → build/Spellbreak.app
open build/Spellbreak.app
```

For a signed / notarized release or Mac App Store `.pkg`, see [`SIGNING_GUIDE.md`](SIGNING_GUIDE.md) and [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md).

## Project layout

```
Sources/Spellbreak/
├── AppDelegate.swift        # launch setup, status item & standard menu shortcuts
├── SpellbreakApp.swift      # entry point, AppState, window controllers
├── OverlayWindow.swift      # full-screen break overlay
├── AuroraBackground.swift   # animated waves + AuroraPalette
├── AmbientParticles.swift   # floating orbs
├── BreakCountdownWindow.swift # heads-up pill before a break
├── SpellTextGenerator.swift # observational message engine
├── PreferencesView.swift    # Time / Vibes / About settings
├── MenuViewSimple.swift     # menu bar popover
├── StatusBarController.swift
├── SoundManager.swift
├── Store.swift              # App Store trial + one-time unlock (App Store builds only)
└── Utilities.swift          # palette, ScreenBusy heuristic
```

## Other docs

- [`AGENTS.md`](AGENTS.md) — project guide: status, repo map, where the truth lives
- [`APP_STORE.md`](APP_STORE.md) — store listing copy
- [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) — Mac App Store submission, step by step
- [`SIGNING_GUIDE.md`](SIGNING_GUIDE.md) — signing, notarization, distribution
- [`PRIVACY.md`](PRIVACY.md) — privacy policy
- [`GLOSSARY.md`](GLOSSARY.md) — code glossary

## License

Copyright © 2025–2026 Pablo Alvarado. All rights reserved.

## Support

[github.com/pibulus/spellbreak](https://github.com/pibulus/spellbreak)
