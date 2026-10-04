# Spellbreak — App Store Listing

Paste-ready copy for App Store Connect. Every claim here is checked against the
code; if a feature changes, change this file with it.

For the step-by-step submission walkthrough, see
[`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md).

---

## App Name

Spellbreak

## Subtitle

Break the screen trance

## Promotional Text

A menu bar break timer for macOS. Set a rhythm, choose a short pause, and let animated color fill the screen for a moment.

## Description

Spellbreak is a break timer for your Mac's menu bar. Choose how often breaks arrive and how long they last. When one begins, a full screen color field fills your displays for a short pause.

Choose a look: Aurora shifts with the time of day, Ember stays warm, Violet stays cool, and Surprise picks one of the three for each break. Turn the optional message on or off, and adjust the sound to suit the room.

Set a heads up notification, start Spellbreak at login, or let it defer breaks while a full screen app is open, microphone input is active, or you're mid-sentence. Time away from your Mac counts as a break. Lock mode hides the hold to skip control.

Breaks last 10 seconds to 3 minutes, at intervals from 15 minutes to 3 hours. Spellbreak runs on macOS 13 or later.

Your settings and break counts stay on your Mac. Spellbreak has no accounts, ads, or analytics, and makes no network requests of its own. Try it for 7 days, then unlock it with a single purchase. No subscription.

## Keywords

break timer,screen break,rest,posture,stretch,pomodoro,reminder,focus,aurora,wellness

(87 of 100.) Two notes, your call: "screen" and "break" are already indexed
from the subtitle, so those slots could carry new words; and the longest break
is 3 minutes, so someone searching "pomodoro" (25/5) won't find what they
expect.

## Category
Primary: Productivity

## Price
The app is **Free**. The price lives on the unlock in-app purchase:
**US$9.99 · A$12.99**, one time, after a 7-day trial. Setup and reasoning are in
the [submission guide](APP_STORE_SUBMISSION.md#pricing).

## In-App Purchases
Two non-consumables: app → Monetization → In-App Purchases. A first IAP has to
ship *with* an app version, so attach both to 1.2.0 before you submit. Product IDs
must match `Store.swift` exactly.

| | Trial | Unlock |
| --- | --- | --- |
| Reference name | 7-Day Trial | Unlock |
| Product ID | `com.pabloalvarado.spellbreak.trial` | `com.pabloalvarado.spellbreak.unlock` |
| Type | Non-Consumable | Non-Consumable |
| Price | Free ($0) | US$9.99 base, Australia set to A$12.99 |
| Display name (30) | 7-Day Trial | Unlock Spellbreak |
| Description (45) | Try scheduled breaks free for 7 days. | Scheduled breaks for good. One purchase. |
| Family Sharing | Off | On (can't be turned off later) |
| Review screenshot | Settings, bottom row, before the trial: "Try Free for 7 Days" | Settings during the trial: "Unlock · A$12.99" |
| Review notes | Free time-based trial per guideline 3.1.1. Its purchase date starts the 7-day clock. | One-time unlock of scheduled breaks once the trial ends. |

The trial *must* be named "7-Day Trial". That's Apple's convention for trials
on one-time purchases, and App Review checks for it.

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

## App Privacy ("nutrition label")
**Data Not Collected.** Nothing leaves the Mac: no analytics, no crash
reporting, no network calls. Matches `PrivacyInfo.xcprivacy` (no tracking, no
collected data types; UserDefaults declared with reason CA92.1). The trial and
unlock go through the App Store; Spellbreak sees only whether they're owned,
never payment details, so the answer stays the same.

## Export Compliance
Handled by `ITSAppUsesNonExemptEncryption = false` in Info.plist — App Store
Connect won't ask.

## Content Rights
"Does your app contain, show, or access third-party content?" → **No**, provided
the sounds in `Resources/Sounds` are yours or licensed for commercial use.
Confirm that before you answer.

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
> • "Lock mode" (in Settings) hides the skip ring and is off by default. Even when
>   on, a break lasts at most 3 minutes.
>
> "Pause while busy": automatic breaks wait while another app is full screen or
> the microphone is in use (e.g. a video call), and for a pause in typing (up to
> 30 seconds). Spellbreak reads only whether the input device is running, through
> Core Audio, and when a key was last pressed, through Quartz. It never captures
> audio or keystrokes, so there are no permission prompts. Test Break and Break
> Now ignore this.
>
> After a few minutes away from the keyboard and mouse, a due break waits and the
> interval starts over on return. With several displays, the break shows on the
> one with the pointer and the others dim to match.
>
> Spellbreak is free to download with a 7-day trial, then a one-time unlock
> (both are in-app purchases). Until the trial starts, Test Break and Break Now
> work but scheduled breaks don't: start it with "Try Free for 7 Days" at the
> bottom of Settings. When the trial ends, scheduled breaks stop until unlocked;
> "Restore Purchase" sits beside the price.
>
> The only permission requested is notifications (optional), for a heads-up 15
> seconds before a break. No account or sign-in.

## Screenshots

2880×1800 (16:10) — upload `screenshots/appstore/*-2880x1800.png`, in order.
Generated by `scripts/generate-appstore-cards.py`; see the submission guide for
adding real captures.

1. **01-break-the-spell** — A pause from the screen, with animated aurora color.
2. **02-street-smart-wisdom** — Short generated phrases; messages are optional.
3. **03-hold-to-skip** — Hold briefly to skip, or enable Lock mode to hide skip controls.
4. **04-living-shaders** — Breaks from 10 seconds to 3 minutes, every 15 minutes to 3 hours.
5. **05-no-subscriptions** — Local preferences and counts; no account, tracking, ads, or subscription.

## URLs

- Support URL: https://spellbreak.app — must be live, with a way to contact you
- Marketing URL: https://spellbreak.app
- Privacy Policy URL: https://spellbreak.app/privacy — must be live at review
  time; publish [`PRIVACY.md`](PRIVACY.md) there

---

## What's New
The first App Store version has no "What's New" field. For later updates:

**1.2.0** (also the website release notes)
• Choose Aurora, Ember, Violet, or Surprise.
• Hide the message for a word free break.
• Adjust break timing, sound, and reminders in Settings.
• Waking your Mac no longer opens straight onto a break.
