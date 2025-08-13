# 🚨 SPELLBREAK DEVELOPMENT GUIDE
> How to not fuck everything up again

## Quick Commands

```bash
# Build and run current version
./build-app.sh && open Spellbreak.app

# Test a different commit/branch
git checkout <commit-or-branch>
./build-app.sh && open Spellbreak.app

# Clean everything and rebuild
swift package clean
rm -rf Spellbreak.app
./build-app.sh && open Spellbreak.app

# Kill all running versions
killall Spellbreak 2>/dev/null
killall Eyedrop 2>/dev/null
```

## YES, You Need to Build Every Time

Unlike web dev (Deno/Svelte), macOS apps MUST be compiled into .app bundles. This means:
- **Every code change** = rebuild with `./build-app.sh`
- **Every git checkout** = rebuild
- **No hot reload** = kill app, rebuild, relaunch

## Project Structure Issues

```
/Projects/active/apps/eyedrop/Eyedrop/  ← CONFUSING NAME!
    ├── Sources/Eyedrop/                 ← ALSO CONFUSING!
    ├── Spellbreak.app                   ← Built app
    ├── Package.swift                    ← Says "Spellbreak"
    └── build-app.sh                     ← Builds Spellbreak
```

The folder is called "Eyedrop" but the app is "Spellbreak" = CONFUSION

## How to Check What's Running

```bash
# See all Eyedrop/Spellbreak apps on system
mdfind "kMDItemFSName == 'Eyedrop.app' || kMDItemFSName == 'Spellbreak.app'"

# Check what's actually running
ps aux | grep -E "(Eyedrop|Spellbreak)" | grep -v grep

# Check menu bar app identity
osascript -e 'tell app "System Events" to get name of every process whose background only is true' | grep -E "(Eye|Spell)"
```

## The Old Good Overlay

Your old Eyedrop.app in /Applications (with three dots icon) has the good overlay. To check what it has:

```bash
# Look at the old app's shader
strings /Applications/Eyedrop.app/Contents/MacOS/Eyedrop | grep -A20 "void main"

# Or just run it to see the effect
open /Applications/Eyedrop.app
```

## Best Practices Going Forward

1. **One app at a time** - Delete old .app bundles before building new ones
2. **Clear naming** - Consider renaming the folder to match the app
3. **Always rebuild** - After ANY code change or git checkout
4. **Check what's running** - Use `ps aux` to verify which version is active
5. **Clean builds** - When confused, `swift package clean` and rebuild

## Why Apple Makes It Hard

- **"Easy"** = Their way (Xcode, Swift UI previews)
- **Hard** = Command line builds, multiple apps, caching issues
- **Reality** = It's NOT easier, just different bullshit than web dev

## To Salvage the Good Overlay

The good overlay is probably in commit 7bb4e15 or in your /Applications/Eyedrop.app. We can:
1. Extract the shader from the old app
2. Check out the old commit and copy the effect
3. Port it to the current version

What do you want to do?