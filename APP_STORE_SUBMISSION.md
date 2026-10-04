# Submitting Spellbreak to the Mac App Store

The whole path, in order. Copy for every field lives in
[`APP_STORE.md`](APP_STORE.md); signing details in
[`SIGNING_GUIDE.md`](SIGNING_GUIDE.md).

**Status of the repo (Oct 2026):** the MAS build script, entitlements, icon,
Info.plist, privacy manifest, privacy policy, listing copy and screenshots are
done. What's left needs you, your Mac, or your Apple account — the ☐ items below.

---

## 0. Decide before you start

### Pricing
**Recommendation: US$9.99, one-time** (was $19.99).

- **No trial, no reviews.** A paid-upfront app can't offer a trial, and on launch
  day it has zero ratings. The price is the whole conversion decision, made
  from five screenshots.
- **The floor is free.** Stretchly, BreakTimer and Time Out's free tier all do
  "remind me to take a break". Spellbreak's case is taste and feel, which
  sells well at an impulse price and badly at a considered one.
- **Polished paid break apps cluster around the $10–15 one-time mark.** At $9.99 you're
  the beautiful one at the friendly price, not the expensive one.
- **You can raise it later.** After reviews land, a move to $12.99 or $14.99 is easy
  to justify. Dropping from $19.99 after a slow launch reads as a markdown.
- **Small Business Program:** enrol and Apple keeps 15%, not 30%. At $9.99 that's about
  $8.49 per sale before tax.

Set **Australia as the base storefront** if you want your home price to be the
fixed one (Apple adjusts the rest for currency and tax). US$9.99 lands at roughly
A$15. A launch-week price (say $6.99, scheduled to step up to $9.99) is a
cheap way to seed the first reviews.

If you'd rather stay premium at $19.99, the copy still works — it just has to
carry more, so the real Settings and menu bar screenshots (step 6) matter more.

### Name and trademark ☐
"Spellbreak" was also the name of Proletariat's battle-royale game (2019–2023,
now under Epic Games), so the word may still be a registered trademark in the
software/games classes. Before you launch:
- Search **IP Australia** (ATMOSS) and **USPTO** for SPELLBREAK in class 9 (and
  41/42).
- Create the App Store Connect record early (step 3) — that's when you find out
  whether the name is free on the store.
- `Spellbreak: Break Reminder` as the store name helps both search and
  distinctiveness. It doesn't remove a trademark issue, if there is one.

---

## 1. Business setup — once ☐

In App Store Connect → **Business** (paid apps can't go live until this is green):
1. **Paid Apps Agreement** — accept it.
2. **Bank account** — add it.
3. **Tax forms** — the US form (W-8BEN for an individual resident in Australia) plus
   your Australian details. Apple collects and remits GST on Australian sales.
4. **Small Business Program** — apply at developer.apple.com/app-store/small-business-program.
   Takes a few days to approve, so do it now.
5. **EU trader status (DSA)** — a paid app is a trader. Without this, the app is
   removed from EU storefronts. You'll give an address, phone and email that
   **are shown publicly on EU product pages** — use details you're comfortable
   publishing.

## 2. Identifiers, certificates, profile — developer.apple.com ☐

1. **Identifiers → App IDs → +** → macOS, explicit Bundle ID
   `com.pabloalvarado.spellbreak`, no capabilities.
2. **Certificates** (Keychain needs both, with private keys):
   - *Apple Distribution*
   - *Mac Installer Distribution* — shows in Keychain as
     `3rd Party Mac Developer Installer: Pablo Alvarado (V433H655PN)`
3. **Profiles → +** → *Mac App Store Connect* → the App ID above → the Apple
   Distribution certificate. Download it and save as
   `Spellbreak_MAS.provisionprofile` in the repo root. It's gitignored.

`./build-mas.sh` checks all of this before it builds, and tells you exactly
what's missing.

## 3. Create the app record — App Store Connect ☐

**Apps → + → New App**
- Platform: **macOS**
- Name: see [`APP_STORE.md`](APP_STORE.md#app-name-30)
- Primary language: English (Australia) or English (U.S.)
- Bundle ID: `com.pabloalvarado.spellbreak`
- SKU: `spellbreak-mac` (yours only; never shown)
- User access: Full

## 4. App Information & Pricing ☐

From [`APP_STORE.md`](APP_STORE.md):
- **App Information:** subtitle, categories, content rights, age rating
  questionnaire answers, privacy policy URL.
- **App Privacy:** Get Started → "No, we do not collect data from this app".
- **Pricing and Availability:** price and base country (step 0); all territories.

## 5. Build and upload — your Mac ☐

```bash
sudo xcode-select -s /Applications/Xcode.app   # full Xcode, current release
./build-mas.sh                                   # → dist/Spellbreak-v1.2.0-mas.pkg
```

Then **Transporter.app** → sign in → drag in the `.pkg` → **Deliver**.
Transporter validates the package before it uploads. Processing takes 10–30
minutes, and you'll get an email when the build appears under the version's
**Build** section.

Each upload needs a new build number. `build-app.sh` stamps one from the clock
(`YYYYMMDDHHMM`), so a rebuild is all it takes.

## 6. Screenshots ☐

`screenshots/appstore/*-2880x1800.png` are upload-ready: five cards, in
order. Every card shows the app, and none carries a price (guideline 2.3.7).

**Stronger: add real captures.** The overlay images inside the cards come from
`scripts/render-theme-assets.swift`, a faithful *re-drawing* of the break
screen rather than a capture of the app. It's close, but it draws the message at
about half its real on-screen size, and it omits the skip ring (the generator
draws that in, at its real spot). That's acceptable, but real captures are
better. Two more shots add a lot, and only the app can provide them:

| File to save | What to capture |
| --- | --- |
| `screenshots/raw/settings.png` | Settings window, Time tab (⌘⇧4, then Space, then click the window) |
| `screenshots/raw/menubar.png` | Menu bar popover open, plus the countdown pill if you can catch it |

Then run `python3 scripts/generate-appstore-cards.py` (needs `pip3 install pillow`).
Settings and menu bar cards are added automatically when those files exist.
Any `screenshots/raw/break-*.png` you capture (⌘⇧3 during a Test Break, on a
plain dark wallpaper) replaces the re-drawn overlay in the cards.

## 7. Version page ☐

On the **1.2.0** version page:
- Screenshots, promotional text, description, keywords, support and marketing
  URLs, copyright: all from [`APP_STORE.md`](APP_STORE.md)
- **Build:** pick the processed build
- **App Review Information:** contact details; sign-in not required; paste the
  review notes
- **Version release:** "Manually release" lets you choose launch day

## 8. Test the real thing first — TestFlight for Mac ☐

The App Store build is sandboxed and signed differently from your local
builds, so a few things only show up there. Add yourself as an internal
tester, install from TestFlight, and run through this:

- [ ] First launch opens Settings; moon icon visible on light **and** dark menu bars
- [ ] Test Break; Break Now; hold-to-skip; Unskippable; mute button on the break screen
- [ ] Start the timer: the notification permission prompt appears; the heads-up
      pill and notification arrive 15 s before a break
- [ ] **Smart Pauses, full screen:** a full-screen video holds the break; it lands
      when you leave full screen
- [ ] **Smart Pauses, calls:** during a FaceTime/Zoom/Meet call, the break holds.
      *This is the one to watch:* the mic check hasn't been run inside the
      sandbox. If it doesn't hold, tell me and I'll swap the approach, or drop
      "calls" from the copy and the card
- [ ] Autostart: the toggle shows "Starts at login", Spellbreak appears in System
      Settings → General → Login Items, and survives a restart
- [ ] **Sleep:** close the lid for longer than your interval, then open it. No
      break on wake; the next one comes a full interval later
- [ ] Settings on a small display, or System Settings → Displays → "Larger Text":
      the window fits and scrolls, and Test Break is reachable
- [ ] VoiceOver: on the break screen, the skip ring offers a "Skip break" action
- [ ] About links open in your browser; sounds play
- [ ] ⌘Q during a break. If it quits, add "⌘Q quits Spellbreak at any time,
      including during a break" to the review notes

## 9. Submit ☐

**Add for Review → Submit.** Reviews usually come back in a day or two. If you
get a rejection, paste it to me with the guideline number.

---

## Known limitation (not a blocker)

**Multiple displays:** the break screen is one window sized to span every
display. With "Displays have separate Spaces" on (macOS's default), a window
can't span displays, so the break most likely covers only one screen and the
others stay usable. Worth fixing soon after launch: one overlay window per
screen, with the message, ring and sound on the main one only. That needs
testing on real hardware, so it isn't in this pass.

## After launch

- Updates go through App Store Connect the same way. "What's New" copy lives in
  [`APP_STORE.md`](APP_STORE.md#whats-new).
- The website DMG (`build-dmg.sh`, Developer ID) can keep shipping alongside
  the App Store version; they're separate builds of the same code.
- **Tahoe icons:** the icon now sits on the standard grid, so macOS 26 shows it
  as-is instead of shrinking it onto a grey tile. For the full Liquid Glass
  treatment, make an Icon Composer `.icon` and compile it with `actool` on a Mac
  with Xcode 26. That's optional polish.
