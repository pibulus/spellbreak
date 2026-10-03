# Spellbreak — App Store Listing

Paste-ready copy for App Store Connect. Every claim here is checked against the
code; if a feature changes, change this file with it. Character limits are
App Store Connect's.

For the step-by-step submission walkthrough, see
[`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md).

---

## App Name (30)
**Spellbreak: Break Reminder** (26)

A descriptive name ranks in search for "break reminder" — the name field
carries the most search weight of anything here. Plain `Spellbreak` (10) also
works if you'd rather keep it clean. Either way, check the name is free when
you create the app record, and see the trademark note in the submission guide.

## Subtitle (30)
**Break the screen trance** (23)

## Promotional Text (170)
When it's time to look up, Spellbreak fills your screen with slow aurora light: a few quiet seconds for your eyes, shoulders and brain. No account. No tracking.

(160 — editable any time without a new review)

## Description (4000)

Lost three hours to the screen again?
Shoulders up around your ears? Forgot to drink water, stretch, or feed the cat?

Spellbreak breaks the trance. Every 20 minutes (or whatever rhythm you set), your screen dissolves into slow, breathing aurora light — a real moment for your eyes, body and brain to reset. Then it gets out of the way.

✨ A BREAK YOU'LL ACTUALLY TAKE
• Full-screen aurora that's hard to ignore and easy to come back from
• A heads-up countdown before it lands, so it never catches you mid-sentence
• Hold the ring for a couple of seconds to skip — just enough friction to make skipping a choice, not a reflex
• Or switch on Unskippable when you want it to hold you to it

🔮 WORDS THAT NOTICE, NOT NAG
Each break can carry a short line, drawn from hundreds and rarely the same one twice. It knows the hour and the moon, and if you skip a few, it notices — gently. It never tells you what to do:
• "The trance gets comfortable"
• "The jaw unhooks itself"
• "Shoulders unspooling"
Prefer just colour and light? Turn the words off.

⚙️ BUILT AROUND YOUR DAY
• Breaks every 15 minutes to 3 hours, lasting 10 seconds to 3 minutes. Set it to 20-20-20 for your eyes, or make it a stretch bell or a tea timer
• Aurora in four moods: shifts with the time of day, always-warm Ember, always-cool Violet, or Surprise
• Smart pauses wait out calls, full-screen games, films and presentations
• Breaks hyperfocus and doomscroll loops without a lecture
• Lives in your menu bar: pause, pick up right where you left off, or take a break now
• Optional ambient sound, with a mute button right on the break screen
• Starts at login, if you want it to

🔒 PRIVATE BY DESIGN
• No account, no analytics, no ads, no tracking
• Never connects to the internet — your settings stay on your Mac
• Never listens: it only checks whether your mic is busy, so a break doesn't land on your call
• One purchase. No subscription.

Break the spell. Your eyes and spine will thank you.

### Claim → code check
| Claim | Where it's true |
| --- | --- |
| Every 20 minutes by default | `breakIntervalMin` default 20 |
| 15 min – 3 h, 10 s – 3 min | `GradientSlider` options in `PreferencesView` |
| Heads-up countdown | `BreakCountdownWindow`, 15 s lead, on by default |
| Hold "a couple of seconds" | hold = break length ÷ 60, clamped to 2 s minimum (2–3 s in practice) |
| Hundreds of lines, rarely twice | ~830 lines; last 60 never redrawn (`SpellTextGenerator`) |
| Hour, moon, notices skips | hour sparks, full/new moon lines, noticing lines |
| Quoted lines | all three are drawable from the generator's pools |
| Smart pauses incl. calls | `ScreenBusy` — fullscreen window or mic in use (verify on the sandboxed build) |
| Never listens | Core Audio "device is running somewhere" property only; no capture, no mic prompt |

Don't put a price in any of this, or in screenshots: prices differ per storefront,
and App Review rejects price references in metadata (guideline 2.3.7 — even "free"
counts). "One purchase. No subscription." describes the model, not a price.

## Keywords (100)
```
eye,strain,eyestrain,20-20-20,posture,stretch,rest,hyperfocus,adhd,focus,timer,wellness,rsi,desk
```
(96) Commas, no spaces. Words already in the name and subtitle ("spellbreak",
"break", "reminder", "screen", "trance") are indexed anyway, so they're not
repeated here. "pomodoro" is out: the longest break is 3 minutes, so a
25/5 pomodoro isn't possible and those searchers would bounce.

## Categories
Primary: **Productivity** · Secondary: **Health & Fitness**

## Age Rating
Answer the questionnaire like this; App Store Connect computes the rating as you
go (expect **4+**):
- In-App Controls: Parental Controls **No** · Age Assurance **No**
- Capabilities: Unrestricted Web Access **No** · User-Generated Content **No** ·
  Social Media **No** · Messaging and Chat **No** · Advertising **No**
- Mature Themes: all **None**
- Medical or Wellness: Medical or Treatment Information **None** ·
  Health or Wellness Topics **Infrequent** (it's a break reminder; answer honestly)
- Sexuality or Nudity: all **None**
- Violence: all **None**
- Chance-Based Activities: all **No / None**

## Price
**Recommendation: US$9.99, one-time.** Reasoning is in
[`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md#pricing). Was $19.99.

## In-App Purchases
None.

## App Privacy ("nutrition label")
**Data Not Collected.** Nothing leaves the Mac: no analytics, no crash
reporting, no network calls. Matches `PrivacyInfo.xcprivacy` (no tracking, no
collected data types; UserDefaults declared with reason CA92.1).

## Export Compliance
Handled by `ITSAppUsesNonExemptEncryption = false` in Info.plist — App Store
Connect won't ask.

## Content Rights
"Does your app contain, show, or access third-party content?" → **No**, provided
the sounds in `Resources/Sounds` are yours or licensed for commercial use.
Confirm that before you answer.

## URLs
- Support URL: https://spellbreak.app — must be live, with a way to contact you
- Marketing URL: https://spellbreak.app
- Privacy Policy URL: https://spellbreak.app/privacy — must be live at review
  time; publish [`PRIVACY.md`](PRIVACY.md) there

## Copyright
`2026 Pablo Alvarado`

## App Review Information
Sign-in required: **No**. Contact: your name, phone, email.

**Notes** (paste as-is):

> Spellbreak is a menu bar app with no Dock icon. After launch, look for the
> moon-and-stars icon in the menu bar; the first launch also opens Settings.
>
> To see a break right away: click "Test Break" at the bottom of Settings, or
> click the menu bar icon and choose "Break Now".
>
> During a break:
> • Press and hold the small "skip" ring at the bottom centre for about 2 seconds
>   to skip. The ring appears 2 seconds into the break.
> • The break also ends on its own after the set duration (20 seconds by default).
> • "Unskippable" (in Settings) is off by default. Even when on, a break lasts at
>   most 3 minutes.
>
> Smart Pauses: automatic breaks wait while another app is full screen or the
> microphone is in use (e.g. a video call). Spellbreak reads only whether the
> input device is running, through Core Audio. It never captures audio, so there
> is no microphone permission prompt. Test Break and Break Now ignore Smart Pauses.
>
> The only permission requested is notifications (optional), for a heads-up 15
> seconds before a break. No account, sign-in, network access, or in-app purchase.

## Screenshots
2880×1800 (16:10) — upload the `screenshots/appstore/*-2880x1800.png` set, in
order. Generated by `scripts/generate-appstore-cards.py`; see the submission
guide for capturing real Settings and menu bar shots to add.

---

## What's New
The first App Store version has no "What's New" field. For later updates,
write it from the user's side, e.g.:

**1.2.0** (also the website release notes)
• Waking your Mac no longer opens straight onto a break — time asleep counts as time away
• Break lines notice when you've skipped a few, and won't repeat themselves for days
• Settings fits smaller screens

### Release history (website builds — not for the store)
- **1.1.0** — Aurora-only vibes; optional break messages; softer, observational
  lines; rebalanced Preferences
- **1.0.4** — Warmer backgrounds, About tab, Surprise Me theme
- **1.0.1** — First launch opens Preferences; native menu bar icon; 20-20-20 interval
- **1.0** — Initial release
