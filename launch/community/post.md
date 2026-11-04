# Spellbreak: full-screen aurora breaks for coding tunnels and hyperfocus (macOS)

I lose track of time pretty badly. Coding, gaming, down a rabbit hole, and suddenly it's dark outside, my tea went cold three hours ago, and I haven't eaten.

I needed something sweet but stern to break the spell, so I made **Spellbreak** for Mac: a small menu bar app that washes every connected display in moving light (Aurora, Ember, or Violet) when an interval comes round, so I actually look out the window, stretch my back, and feed the cat.

## How it works
- **Default 20-20-20 cadence:** 20-second breaks every 20 minutes out of the box (configurable from 10s to 3m breaks, 15m to 3h intervals).
- **Deliberate friction or full lock:** A 2-3 second hold on the ring leaves early if a build is on fire. Flip **Lock mode** on and the skip ring disappears completely until the clock runs out.
- **Call-aware without permissions:** Checks whether an input device is active via Core Audio (just a boolean, zero audio captured) so a break never lands on top of a Zoom, Meet, or Slack call. Also waits briefly if keys are actively moving.
- **No streaks, no shame:** Skip a break and nothing scolds or resets. No accounts, no analytics, zero network requests at all. Sandboxed and Apple-notarized for macOS 13+ (Apple silicon & Intel).

It's a one-time purchase (~US$13 / A$19) at **https://spellbreak.app**, and there's an interactive live break preview right on the page if anyone wants to feel the hold-to-skip ring in the browser first.

Happy to answer anything about how the multi-display overlay or Core Audio call check works under the hood!
