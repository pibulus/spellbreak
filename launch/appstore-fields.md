# App Store Connect — the fields only a human can fill

Every field on the portal's app page, with a draft to paste and edit. The
portal is the one part no script can do: `POST /v1/apps` returns
`FORBIDDEN_ERROR: resource 'apps' does not allow 'CREATE'` even for an Admin
key. So this file exists to make that single sitting as short as possible.

Checked against `../APP_STORE.md` and `../APP_STORE_SUBMISSION.md`. The numbers
here (A$29 direct, US$9.99 / A$14.99 store unlock) are the decided ones as of
2 Nov 2026.

---

## App record (Apps → + → New App)

| Field | Value |
| --- | --- |
| Platform | macOS |
| Name | Spellbreak |
| Primary language | English (Australia) |
| Bundle ID | `com.pabloalvarado.spellbreak` |
| SKU | `spellbreak-mac` |
| User access | Full |

If the name is taken — Spellbreak was a 2019 battle royale — fall back to
**Spellbreak – Break Reminder**, and say so before the description does.

---

## App Information

| Field | Draft |
| --- | --- |
| **Subtitle** (30) | Break the screen trance |
| **Primary category** | Productivity |
| **Secondary category** | Health & Fitness |
| **Content rights** | Does not contain third-party content |
| **Age rating** | 4+ — nothing in any category; In-App Controls: Parental Controls No, Age Assurance No; Health or Wellness Topics *Infrequent* (answer honestly, it's a break reminder) |
| **Privacy policy URL** | https://spellbreak.app/privacy |
| **Support URL** | https://spellbreak.app/support |
| **Marketing URL** | https://spellbreak.app |
| **Copyright** | © 2025–2026 Pablo Alvarado |

**App Privacy** → Get Started → "No, we do not collect data from this app".
That is true of the *app*; the website counts page views and says so on
`/privacy`.

---

## Version 1.2.0

**Promotional text** (170) — editable without a new build:

> A menu bar break timer for macOS. Twenty seconds of moving colour instead of
> a corner banner. Hold to leave, or lock it and the break runs its clock.

**Description** (4000) — first person, because that is what the About says too:

```
I lose track of time. Coding, gaming, watching videos — then it is dark, I am
hungry, and I have not eaten.

I needed something sweet but stern to break me from my spell, so I made
Spellbreak: a small thing that takes over the screen for a moment and reminds me
to feed the cat, look out the window, stretch my back.

Breaks can be unskippable, or skippable if that is the kind of day it is. The
length and the gap are set by hand. The colours drift with the clock or stay
where they are put, and the little fortunes arrive or do not.

Foggy eyes, a stiff back, a cup of tea going cold.

Try it free for 7 days, then unlock it once (US$9.99 / A$14.99). Handmade with love in Melbourne.

Requires macOS 13 or later. Apple silicon and Intel. It never records audio; it
only asks whether the microphone is in use, which is how it knows to hold during
a call. No network access at all.
```

**Keywords** (100 chars, comma separated, no spaces):

```
break timer,screen break,rest,posture,stretch,pomodoro,reminder,focus,aurora,wellness
```

**Review notes** — the paragraph a reviewer reads before judging it:

```
Spellbreak is a menu bar break timer. The free download starts a 7-day trial
(the free "7-Day Trial" in-app purchase); after it ends, scheduled breaks need
the one-time unlock. Test Break and Break Now work without either.

The app defers breaks while microphone input is active, which it detects by
asking Core Audio whether an input device is running. It never records audio and
asks for no microphone permission. It also defers during full-screen apps and
brief pauses in typing, and treats time away as a break.

Lock mode hides the hold-to-skip control; that is a preference, off by default.
Nothing here contacts a server: the app has no network entitlement.
```

---

## In-App Purchases (two non-consumables, attached to 1.2.0)

| | Trial | Unlock |
| --- | --- | --- |
| Reference name | 7-Day Trial | Unlock |
| Product ID | `com.pabloalvarado.spellbreak.trial` | `com.pabloalvarado.spellbreak.unlock` |
| Price | Free ($0) | US$9.99 base, Australia **A$14.99** |
| Display name (30) | 7-Day Trial | Unlock Spellbreak |
| Description (45) | Try scheduled breaks free for 7 days. | Scheduled breaks for good. One purchase. |
| Family Sharing | Off | On |
| Review screenshot | Settings before the trial: "Try Free for 7 Days" | Settings during the trial: "Unlock · A$14.99" |

The trial **must** be named "7-Day Trial" — that is Apple's convention for a
trial on a one-time unlock, and App Review looks for it.

---

## Screenshots

Four sizes already rendered in `../screenshots/appstore/` — 1280×800, 1440×900,
2560×1600, 2880×1800. They show the real app, which is what 2.3.3 checks. The
card set is `01-break-the-spell` … `05-no-subscriptions`.

---

## What would get rejected, and what to do about it

- **4.2 minimum functionality** — the usual trap for timers. The description
  above leads with what the app does beyond a timer: pointer-screen anchoring
  with mirrors, deferral during calls and typing, palettes, Lock mode.
- **2.3.7 metadata** — screenshots must be the app (they are), and the name must
  be free. Have the fallback name ready.
- **3.1.1** — the trial shape is documented by Apple; the review notes explain
  it explicitly so a reviewer doesn't have to infer it.
- **A rejection is a same-day fix**: edit a field, swap a screenshot, resubmit.

---

*Draft these, don't trust them. Read every line out loud before it goes in — the
copy voice is "the one where I look up and it is dark", not "Spellbreak is a
desktop app for".*
