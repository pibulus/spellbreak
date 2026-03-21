# Spellbreak Distribution Guide

## Current Status: Beta Distribution Ready ✅

### What's Available Now

**Unsigned Beta Download**
- Location: `/static/Spellbreak-v1.0-unsigned.zip` (13MB)
- Version: 1.0 (unsigned)
- Installation: Right-click → Open (bypasses Gatekeeper warning)
- Website: https://spellbreak.app

### Website Changes Made

1. **Download Button Added**
   - Big amber "Download Beta - Free" button on homepage
   - Replaces $9 payment button (commented out for now)
   - Direct ZIP download from `/static/` folder

2. **Installation Instructions Section**
   - Step-by-step guide for unsigned app
   - Explains right-click → Open process
   - Sets expectations about beta status

3. **User Journey**
   - Hero → Download → Installation Guide → Features → Truth Moment

### Installation Process for Users

1. **Download**: Click "Download Beta - Free"
2. **Extract**: Double-click ZIP to extract Spellbreak.app
3. **First Launch**: Right-click app → "Open" → Click "Open" in dialog
4. **Subsequent Launches**: Normal double-click works

### What Happens With Developer ID ($99)

Once you get Apple Developer ID, you can:

1. **Sign the app**
   ```bash
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: Your Name (TEAM_ID)" \
     --options runtime \
     --entitlements Spellbreak.entitlements \
     Spellbreak.app
   ```

2. **Notarize it**
   ```bash
   # Create DMG
   hdiutil create -volname "Spellbreak" \
     -srcfolder Spellbreak.app \
     -ov -format UDZO \
     Spellbreak-v1.0.dmg

   # Submit for notarization
   xcrun notarytool submit Spellbreak-v1.0.dmg \
     --keychain-profile "AC_PASSWORD" \
     --wait

   # Staple the ticket
   xcrun stapler staple Spellbreak-v1.0.dmg
   ```

3. **Update website**
   - Replace ZIP with signed DMG
   - Remove "unsigned" warnings
   - Change button to "Download Spellbreak"
   - Remove installation instructions (installs normally)

4. **Submit to App Store**
   - Follow SIGNING_GUIDE.md steps
   - Create app in App Store Connect
   - Upload via Xcode or Transporter
   - Submit for review

### Website Deployment

The spellbreak-site is a Deno Fresh app. To deploy changes:

```bash
cd /Users/pabloalvarado/Projects/active/mac/spellbreak-site

# If you have a deployment setup:
deno task deploy

# Or via Deno Deploy:
deployctl deploy
```

### File Locations

```
spellbreak/
├── build/Spellbreak.app          # Built app
├── Spellbreak-v1.0-unsigned.zip  # Distribution package
├── APP_STORE.md                  # Store listing
├── SIGNING_GUIDE.md              # Code signing instructions
└── PRIVACY.md                    # Privacy policy

spellbreak-site/
├── routes/index.tsx              # Homepage (updated with download)
├── static/
│   └── Spellbreak-v1.0-unsigned.zip  # Download file
└── GLOSSARY.md                   # Site reference
```

### Next Steps

**Immediate (Beta Distribution)**
- [x] Create unsigned ZIP
- [x] Add to website
- [x] Add installation instructions
- [ ] Deploy website updates
- [ ] Test download flow
- [ ] Share with early users

**Once You Have Developer ID**
- [ ] Purchase Apple Developer account ($99)
- [ ] Sign the app with Developer ID
- [ ] Notarize the app
- [ ] Create signed DMG
- [ ] Update website with signed version
- [ ] Remove "unsigned" warnings

**App Store Submission**
- [ ] Create app icon images (10 sizes)
- [ ] Take 6 screenshots
- [ ] Set up App Store Connect
- [ ] Upload build via Xcode
- [ ] Submit for review

### Testing the Download

1. Visit https://spellbreak.app (once deployed)
2. Click "Download Beta - Free"
3. Extract and right-click → Open
4. Set break interval
5. Wait for first break
6. Test hold-to-skip mechanism

### Support Strategy

**Common Issues:**
- "App is damaged" → Make sure to right-click → Open, not double-click
- "Unidentified developer" → Expected for unsigned builds
- Won't open at all → Check macOS version (needs 13.0+)

**Beta Feedback Loop:**
- GitHub Issues: https://github.com/pibulus/spellbreak/issues
- Direct feedback welcome before App Store launch
- Use beta period to refine before charging $9

---

*Ready to break the spell.* 🔮
