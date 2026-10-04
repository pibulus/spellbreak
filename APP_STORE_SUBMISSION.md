# Submitting Spellbreak to the Mac App Store

The whole path, in order. Copy for every field lives in
[`APP_STORE.md`](APP_STORE.md); signing details in
[`SIGNING_GUIDE.md`](SIGNING_GUIDE.md).

**Status of the repo (Oct 2026):** the MAS build script, entitlements, icon,
Info.plist, privacy manifest, privacy policy, listing copy, screenshots, the
7-day trial with one-time unlock, and the smart breaks (away, typing, every
display) are done. None of the Swift has been compiled yet, so the first build
on your Mac is the real check. What's left needs you, your Mac, or your Apple
account: the ☐ items below.

---

## 0. Decide before you start

### Pricing
**Model: free download, 7-day trial, one-time unlock: US$9.99 · A$12.99.**

Apple has no trials for paid-upfront apps, but guideline 3.1.1 explicitly allows
this shape for one-time purchases: a free in-app purchase named "7-Day Trial"
starts the clock, then a paid unlock. `Store.swift` implements it, in App Store
builds only; the website build stays unlocked. Test Break and Break Now always
work. The trial and the unlock gate only *scheduled* breaks.

**Why a trial: everyone serious in this category lets people try first.**

| App | Model | Price |
| --- | --- | --- |
| LookAway | Free download + IAP, free trial; also direct and Setapp | MAS: $4.99/mo, $14.99/yr, $49.99 lifetime · direct from $19 one-time |
| Time Out (Dejal) | Free, optional supporter tips | $0 |
| Restier | 14-day trial, then a licence | €7.99/yr or €19.99 lifetime |
| Stretchly · BreakTimer · Workrave | Free, open source | $0 |
| EyeBreak · StandLock | Free | $0 |
| **Spellbreak** | **Free download, 7-day trial, one-time unlock** | **US$9.99 · A$12.99** |

From search results, Oct 2026. The App Store and these sites were blocked from
where this was researched, so check a competitor's store page before quoting it.

An unknown paid app with no ratings asks for ten dollars on the strength of five
screenshots, next to free alternatives. A trial lets the break itself do the
selling, and the break is the best thing Spellbreak has.

**Why US$9.99.** It's the cheapest paid option in that table, with no subscription,
and well under LookAway's lifetime price. Raise it to $12.99–14.99 once reviews
land. Raising after launch is easy; dropping later reads as a markdown.

**A$12.99 is a home-turf discount, not parity.** Australian prices include GST.
Ex-GST, A$12.99 is about US$8.20 at Oct 2026 rates (~0.695), ~18% under the US
price. Parity would be about A$15.99. Fine if that's the intent.

**What you keep**, on the Small Business Program (15%):

| Sale | Less tax | Your cut |
| --- | --- | --- |
| US$9.99 | US sales tax is added on top | ~US$8.49 |
| A$12.99 | A$11.81 after GST | ~A$10.04 (~US$6.98) |

**Setting two prices.** The app itself is Free. On the **Unlock** IAP's price
schedule, set base country United States at US$9.99, then adjust Australia by
hand to A$12.99. Apple keeps adjusting the other storefronts for currency and
tax, but not the ones you've set yourself. If A$12.99 isn't on the AUD list,
take the nearest.

**Seeding reviews (optional).** Schedule a launch-week price on the unlock
(say US$6.99), stepping back up to $9.99 after. Watch trial starts versus
unlocks in App Store Connect's Sales and Trends; that ratio is your conversion.

### Website ☐
The About tab links to spellbreak.app, and the README says the DMG downloads
from there. If the site hands out the full website build (no trial, no lock),
anyone can skip the App Store purchase, so the App Store sale only ever
catches people who didn't look. Pick one:
- **Point the site at the App Store** (recommended): an "Download on the Mac App
  Store" badge, and the DMG retired. Simplest, and it keeps every sale in one place.
- **Keep the DMG, but sell it** (Gumroad, Paddle): needs licence-key code in the
  website build. Not in the app today.

Either way, the site needs a support/contact route and `/privacy` (publish
[`PRIVACY.md`](PRIVACY.md)) live before you submit; App Review opens both. And
don't put a "buy outside the App Store" link on the page the app links to:
steering buyers off the App Store is a guideline 3.1.1 problem.

The repo is public too, so anyone handy with Xcode can build Spellbreak
unlocked. Most buyers won't bother, and plenty of indie apps sell fine that way;
make it private if you'd rather not.

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
- Name: see [`APP_STORE.md`](APP_STORE.md#app-name)
- Primary language: English (Australia) or English (U.S.)
- Bundle ID: `com.pabloalvarado.spellbreak`
- SKU: `spellbreak-mac` (yours only; never shown)
- User access: Full

## 4. App Information & Pricing ☐

From [`APP_STORE.md`](APP_STORE.md):
- **App Information:** subtitle, categories, content rights, age rating
  questionnaire answers, privacy policy URL.
- **App Privacy:** Get Started → "No, we do not collect data from this app".
- **Pricing and Availability:** the app is **Free**, all territories.
- **In-App Purchases:** create the Trial and Unlock non-consumables from the table
  in [`APP_STORE.md`](APP_STORE.md#in-app-purchases), with the Unlock prices from
  step 0. Each needs a review screenshot of the Settings row that sells it. Take
  them from the TestFlight build in step 8, then attach both to the version.

## 5. Build and upload — your Mac ☐

```bash
sudo xcode-select -s /Applications/Xcode.app   # full Xcode, current release
./build-mas.sh                                   # → dist/Spellbreak-v1.2.0-mas.pkg, unlock included
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

**Strongest of all: an App Preview video.** Spellbreak is motion, and a still
can't show the aurora breathing. QuickTime → New Screen Recording during a Test
Break, then trim to 15–30 seconds. The format is landscape 1920×1080 (crop the
16:10 recording), .mov or .mp4, H.264, 30 fps; up to three per app. It must be
footage of the app itself, not the re-drawn overlays. Upload it alongside the
screenshots on the version page.

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
- [ ] Test Break; Break Now; hold-to-skip; Lock mode; mute button on the break screen
- [ ] Start the timer: the notification permission prompt appears; the heads-up
      pill and notification arrive 15 s before a break
- [ ] **Pause while busy, full screen:** a full-screen video holds the break; it lands
      when you leave full screen
- [ ] **Pause while busy, calls:** during a FaceTime/Zoom/Meet call, the break holds.
      *This is the one to watch:* the mic check hasn't been run inside the
      sandbox. If it doesn't hold, tell me and I'll swap the approach, or drop
      "calls" from the copy and the card
- [ ] Autostart: the toggle shows "Starts at login", Spellbreak appears in System
      Settings → General → Login Items, and survives a restart
- [ ] **Sleep:** close the lid for longer than your interval, then open it. No
      break on wake; the next one comes a full interval later
- [ ] **Away:** hands off keyboard and mouse for 4+ minutes, across the time a
      break is due. Nothing fires while you're away (no heads-up notification
      either); touch the mouse and no break lands; the next comes a full
      interval later
- [ ] **Typing:** keep typing as a break comes due. It waits for two quiet
      seconds, 30 seconds at most, then lands. With "Pause while busy" off, it
      doesn't wait
- [ ] **Several displays:** the break, with its line, ring and sound, lands on the
      display with the pointer. Every other display shows the same aurora, fades
      out with it, and swallows clicks. Try "Displays have separate Spaces" on
      (the default) and off, and Surprise to check every display matches
- [ ] **Today's tally:** after a break the menu reads "1 break today"; it survives
      a quit and relaunch, and resets after midnight
- [ ] Settings on a small display, or System Settings → Displays → "Larger Text":
      the window fits and scrolls, and Test Break is reachable
- [ ] VoiceOver: on the break screen, the skip ring offers a "Skip break" action
- [ ] **Trial, fresh install** (TestFlight purchases are free sandbox ones): the
      bottom of Settings shows "Try Free for 7 Days", and the caption names the
      unlock price in your storefront's currency. The menu bar's Start opens
      Settings instead of starting. Start the trial: a $0 purchase sheet, then the
      timer starts and the caption shows days left
- [ ] **Trial ending:** quit, then relaunch from Terminal with
      `SPELLBREAK_TRIAL_SECONDS=120 /Applications/Spellbreak.app/Contents/MacOS/Spellbreak`
      (the trial can only be shortened this way, never stretched). After two
      minutes, the next due break opens Settings with "Your free week is up"
      instead, and the timer stops. Test Break still works
- [ ] **Unlock:** the purchase sheet shows the local price; afterwards the row
      collapses back to just Test Break and the timer resumes
- [ ] **Restore Purchase** after a reinstall, or on a second Mac, brings the
      unlock back
- [ ] About links open in your browser; sounds play
- [ ] ⌘Q during a break. If it quits, add "⌘Q quits Spellbreak at any time,
      including during a break" to the review notes

## 9. Submit ☐

**Add for Review → Submit.** Reviews usually come back in a day or two. If you
get a rejection, paste it to me with the guideline number.

---

## After launch

- Updates go through App Store Connect the same way. "What's New" copy lives in
  [`APP_STORE.md`](APP_STORE.md#whats-new).
- The website DMG (`build-dmg.sh`, Developer ID) is the same code built without
  `-DAPP_STORE`: no trial, no lock. See "Website" in step 0 before shipping it
  alongside the App Store version.
- **Tahoe icons:** the icon now sits on the standard grid, so macOS 26 shows it
  as-is instead of shrinking it onto a grey tile. For the full Liquid Glass
  treatment, make an Icon Composer `.icon` and compile it with `actool` on a Mac
  with Xcode 26. That's optional polish.
