# Spellbreak · launch kit

Initially scaffolded by [Launch Arsenal](https://github.com/pibulus/claude-config)
from `apps/launch-arsenal/briefs/spellbreak.yaml`, then **hand-rewritten on
2026-11-04** (`social/`, `community/`, `email/`, `angles.md`, and
`release/changelog.md`) in Pablo's maker voice.

> **Heads-up before regenerating:** running `deno task launch` will overwrite
> those hand-written files with raw template output. Re-run `deno task arsenal`
> freely for `audit/` checks, or copy `social/`, `community/`, and `email/`
> aside before re-running `deno task launch`.

## What's in here

| Path | What it is |
| --- | --- |
| `index.html` | The kit as a page. Open this first — it's the whole thing laid out instead of hunted through |
| `angles.md` | Four hooks onto the same product: plain description, problem note, feature note, feedback ask. Pick one; don't use all four |
| `social/thread.txt` | A thread, numbered tweet by tweet |
| `social/caption-options.txt` | Short captions for wherever a single line is needed |
| `community/post.md` | A maker-community post: why it exists, what it does |
| `email/` | `subject.txt`, `launch.txt`, `launch.html` — for people who already know you |
| `website/` | `hero.md` and `meta.json` — the site's own words, for cross-checking against what's live |
| `release/changelog.md` | The release note, rewritten from the brief |
| `assets/` | 1200×630 OG card, square, IG story, comparison card. All generated from the brief's palette |
| `audit/` | Readiness of the live site: `readiness.json` (currently 21 pass, 2 warn, 0 fail), `ARSENAL.md`, and mobile/wide captures |
| `messaging-core.json`, `run.json` | Provenance: the normalised messaging context and what was run when |

## Regenerate

```bash
cd ~/Projects/active/apps/launch-arsenal

deno task launch --brief briefs/spellbreak.yaml \
  --out ~/Projects/active/mac/spellbreak/launch

deno task arsenal --repo ../../mac/spellbreak-site --url https://spellbreak.app \
  --capture-screenshots --out ~/Projects/active/mac/spellbreak/launch/audit
```

The brief is the only input that matters. Change the brief, not the output.

## The brief knows things the generator would otherwise guess wrong

- **One-time app sale, A$29.** Not a supporter pass, not a yearly membership.
  ZipList and TalkType in the same fleet sell `$29/year` passes and their copy
  reads like a membership — that language must never appear here.
- **The Mac App Store lane is parked.** No trial, no US$9.99, no "also on the
  App Store". One price, one way to buy.
- **Lock mode is the only thing called unskippable.** The default break has a
  2–3 second hold, on purpose.
- Never a hold longer than 3 seconds or a break longer than 3 minutes.

## Before anything goes out

1. Rewrite the copy. The generator is good at structure and mediocre at voice;
   it produced "is clear enough on first use, especially on mobile" for a Mac app.
2. Check every factual claim against `../AGENTS.md` — that file owns the numbers.
3. Point the link at `https://spellbreak.app`, which sells the thing the card
   describes.
