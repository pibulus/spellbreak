#!/usr/bin/env python3
"""
App Store story cards for Spellbreak, at 2880x1800 and 1440x900 (16:10, the Mac
App Store sizes). Run from the repo root:

    pip3 install pillow
    python3 scripts/generate-appstore-cards.py

Inputs, best first. Real captures always win over re-drawn stand-ins:
  screenshots/raw/break-aurora.png, break-ember.png, break-violet.png
      real captures of a break (⌘⇧3 during a Test Break, plain dark wallpaper)
  screenshots/raw/break-skip.png      real capture mid-hold on the skip ring
  screenshots/raw/settings.png        Settings window → adds a "make it yours" card
  screenshots/raw/menubar.png         menu bar popover → adds a "menu bar" card
  screenshots/{aurora,ember,violet}-2880x1800.png
      the fallback: overlays re-drawn by scripts/render-theme-assets.swift

What every card keeps to (App Review 2.3.3 / 2.3.7):
  - it shows the app; images are cropped to fit, never stretched
  - no prices: they differ per storefront, and App Review counts even "free"

Fonts: SF Pro / SF Rounded when present (any Mac). Elsewhere, Inter / Nunito are
fetched once from Google Fonts into ~/.cache/spellbreak-fonts.
"""

import math
import re
import sys
import urllib.request
from functools import lru_cache
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "screenshots"
RAW = SHOTS / "raw"
OUT = SHOTS / "appstore"

W, H = 2880, 1800                       # cards are drawn at 2880 and downsampled for 1440
CONTENT = (230, 400, 2650, 1730)        # left, top, right, bottom of the image area

CREAM = (252, 245, 232)
PEACH = (255, 191, 89)                  # badge / pillar titles
LILAC = (224, 209, 245)                 # subheads


# MARK: - Fonts

SF = Path("/System/Library/Fonts/SFNS.ttf")
SF_ROUNDED = Path("/System/Library/Fonts/SFNSRounded.ttf")
FONT_CACHE = Path.home() / ".cache" / "spellbreak-fonts"
WEIGHTS = {"black": 900, "heavy": 800, "bold": 700, "semibold": 600, "medium": 500}


def google_font(family, weight):
    path = FONT_CACHE / f"{family}-{weight}.ttf"
    if not path.exists():
        FONT_CACHE.mkdir(parents=True, exist_ok=True)
        css_url = f"https://fonts.googleapis.com/css2?family={family}:wght@{weight}"
        # An old user agent gets TTF links back instead of woff2
        request = urllib.request.Request(css_url, headers={"User-Agent": "Wget/1.21"})
        css = urllib.request.urlopen(request, timeout=30).read().decode()
        ttf_url = re.search(r"url\((https://[^)]+\.ttf)\)", css).group(1)
        path.write_bytes(urllib.request.urlopen(ttf_url, timeout=30).read())
    return path


def variable_font(path, size, weight):
    font = ImageFont.truetype(str(path), size)
    try:
        values = []
        for axis in font.get_variation_axes():
            name = axis.get("name", b"")
            name = name.decode() if isinstance(name, bytes) else name
            if name.lower() == "weight":
                values.append(min(max(weight, axis["minimum"]), axis["maximum"]))
            else:
                values.append(axis["default"])
        font.set_variation_by_axes(values)
    except Exception:
        pass  # a static face, or a FreeType without variations: use it as it comes
    return font


@lru_cache(maxsize=None)
def font(style, size):
    if style == "rounded":
        if SF_ROUNDED.exists():
            return variable_font(SF_ROUNDED, size, 500)
        return ImageFont.truetype(str(google_font("Nunito", 700)), size)
    if SF.exists():
        return variable_font(SF, size, WEIGHTS[style])
    return ImageFont.truetype(str(google_font("Inter", WEIGHTS[style])), size)


# MARK: - Drawing helpers

def background():
    """The cards' night-sky ground: a deep violet gradient with a soft glow up top."""
    y = np.linspace(0, 1, H)[:, None, None]
    top, mid, bottom = np.array([13, 8, 23]), np.array([23, 13, 41]), np.array([10, 5, 20])
    rows = np.where(y < 0.5, top + (mid - top) * (y / 0.5), mid + (bottom - mid) * ((y - 0.5) / 0.5))
    rgb = np.broadcast_to(rows, (H, W, 3)).astype(np.float32)

    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt((xx - W * 0.5) ** 2 + (yy - H * 0.15) ** 2) / (W * 0.55)
    glow = np.clip(1 - d, 0, 1)
    tint = np.array([166, 89, 242], np.float32)
    rgb = rgb + (tint - rgb) * (glow ** 1.6 * 0.18)[..., None]
    return Image.fromarray(rgb.clip(0, 255).astype(np.uint8), "RGB").convert("RGBA")


def fill_crop(img, w, h, focus=(0.5, 0.5)):
    """Aspect-fill: scale to cover w x h, crop the overflow around `focus`."""
    scale = max(w / img.width, h / img.height)
    sw, sh = math.ceil(img.width * scale), math.ceil(img.height * scale)
    scaled = img.resize((sw, sh), Image.LANCZOS)
    left = round((sw - w) * focus[0])
    top = round((sh - h) * focus[1])
    return scaled.crop((left, top, left + w, top + h))


def fit_size(img, max_w, max_h, max_scale=None):
    scale = min(max_w / img.width, max_h / img.height)
    if max_scale is not None:
        scale = min(scale, max_scale)
    return round(img.width * scale), round(img.height * scale)


def screen_size(max_w, max_h):
    """The biggest 16:10 box that fits — the shape of the screens being shown."""
    w = min(max_w, max_h * 16 / 10)
    return round(w), round(w * 10 / 16)


def rounded_mask(w, h, radius, ss=4):
    big = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(big).rounded_rectangle((0, 0, w * ss - 1, h * ss - 1), radius * ss, fill=255)
    return big.resize((w, h), Image.LANCZOS)


def shadow(card, box, radius, offset=24, blur=48, opacity=0.6):
    x0, y0, x1, y1 = box
    pad = blur * 3
    layer = Image.new("L", (x1 - x0 + pad * 2, y1 - y0 + pad * 2), 0)
    ImageDraw.Draw(layer).rounded_rectangle((pad, pad, pad + x1 - x0, pad + y1 - y0), radius, fill=int(255 * opacity))
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    black = Image.new("RGBA", layer.size, (0, 0, 0, 255))
    black.putalpha(layer)
    card.alpha_composite(black, (x0 - pad, y0 - pad + offset))


def framed(card, img, box, radius=36):
    """Paste `img` (already sized to `box`) as a rounded, shadowed screen."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    shadow(card, box, radius)
    tile = img.convert("RGBA").resize((w, h), Image.LANCZOS) if img.size != (w, h) else img.convert("RGBA")
    tile.putalpha(rounded_mask(w, h, radius))
    card.alpha_composite(tile, (x0, y0))
    stroke = Image.new("RGBA", card.size, (0, 0, 0, 0))
    ImageDraw.Draw(stroke).rounded_rectangle(box, radius, outline=(217, 166, 255, 90), width=3)
    card.alpha_composite(stroke)


def tracked_width(text, fnt, tracking):
    return sum(fnt.getlength(ch) for ch in text) + tracking * (len(text) - 1)


def draw_tracked(draw, x, y, text, fnt, fill, tracking):
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += fnt.getlength(ch) + tracking


def wrap(text, fnt, max_width):
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if fnt.getlength(trial) <= max_width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    lines.append(line)
    return lines


def header(card, badge, headline, sub):
    draw = ImageDraw.Draw(card)
    badge_font = font("bold", 26)
    tracking = 4
    bw = tracked_width(badge, badge_font, tracking)
    draw_tracked(draw, (W - bw) / 2, 112, badge, badge_font, PEACH + (242,), tracking)

    draw.text((W / 2, 160), headline, font=font("black", 86), fill=CREAM, anchor="ma")

    sub_font = font("medium", 36)
    for i, line in enumerate(wrap(sub, sub_font, W * 0.72)):
        draw.text((W / 2, 290 + i * 48), line, font=sub_font, fill=LILAC + (205,), anchor="ma")


def label_pill(card, box, title, caption):
    x0, y0, x1, y1 = box
    layer = Image.new("RGBA", card.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(box, 22, fill=(20, 10, 36, 224), outline=(255, 255, 255, 52), width=2)
    d.text((x0 + 30, y0 + 22), title, font=font("bold", 30), fill=CREAM + (242,))
    d.text((x0 + 30, y0 + 64), caption, font=font("medium", 24), fill=LILAC + (190,))
    card.alpha_composite(layer)


# MARK: - The skip ring, as OverlayWindow draws it

def draw_skip_ring(img, progress, pt):
    """Mid-hold skip ring: 64pt, centred 92pt above the bottom edge (60pt padding
    + half the ring), scaled 1.15 while held, percentage in SF Rounded. `pt` is
    pixels per point in `img`. Returns the ring's centre."""
    ss = 4
    s = 1.15 * pt
    cx, cy = img.width / 2, img.height - 92 * pt
    radius = 32 * s
    box = int(radius * 2 + 40 * pt)
    layer = Image.new("RGBA", (box * ss, box * ss), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    c = box * ss / 2
    r = radius * ss

    def ring_box(rr):
        return (c - rr, c - rr, c + rr, c + rr)

    d.ellipse(ring_box(r), outline=CREAM + (64,), width=round(3 * s * ss))          # track, 0.25
    width = round(4 * s * ss)
    end = -90 + 360 * progress
    d.arc(ring_box(r), -90, end, fill=CREAM + (204,), width=width)                     # progress, 0.8
    for angle in (-90, end):                                                           # round caps
        a = math.radians(angle)
        px, py = c + (r - width / 2) * math.cos(a), c + (r - width / 2) * math.sin(a)
        d.ellipse((px - width / 2, py - width / 2, px + width / 2, py + width / 2), fill=CREAM + (204,))
    d.text((c, c), f"{round(progress * 100)}", font=font("rounded", round(16 * s * ss)),
           fill=CREAM + (230,), anchor="mm")

    layer = layer.resize((box, box), Image.LANCZOS)
    img.alpha_composite(layer, (round(cx - box / 2), round(cy - box / 2)))
    return cx, cy


def loupe(card, source, center_src, src_to_card, at, radius=200, magnify=3.2):
    """A magnified circular callout of `source` around center_src, drawn at `at`."""
    sx, sy = center_src
    r_src = radius / (magnify * src_to_card)
    crop = source.crop((round(sx - r_src), round(sy - r_src), round(sx + r_src), round(sy + r_src)))
    crop = crop.resize((radius * 2, radius * 2), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (radius * 2 * 4,) * 2, 0)
    ImageDraw.Draw(mask).ellipse((0, 0, radius * 8 - 1, radius * 8 - 1), fill=255)
    crop.putalpha(mask.resize((radius * 2,) * 2, Image.LANCZOS))

    ax, ay = at
    shadow(card, (ax - radius, ay - radius, ax + radius, ay + radius), radius, offset=16, blur=36, opacity=0.55)
    card.alpha_composite(crop, (ax - radius, ay - radius))
    ring = Image.new("RGBA", card.size, (0, 0, 0, 0))
    ImageDraw.Draw(ring).ellipse((ax - radius, ay - radius, ax + radius, ay + radius),
                                 outline=CREAM + (150,), width=4)
    card.alpha_composite(ring)


# MARK: - Inputs

def load(*candidates):
    for path in candidates:
        if path.exists():
            return Image.open(path).convert("RGBA"), path
    return None, None


def overlay(theme):
    """A break screen in `theme`: a real capture if there is one, else the re-drawing."""
    img, path = load(RAW / f"break-{theme}.png", SHOTS / f"{theme}-2880x1800.png")
    if img is None:
        sys.exit(f"missing break image for {theme}: add screenshots/raw/break-{theme}.png")
    return img, path.parent == RAW


# MARK: - Cards

def card_hero():
    card = background()
    header(card, "A PAUSE FROM THE SCREEN", "Let the screen go quiet.",
           "Set a rhythm. Let animated aurora color fill a short break.")
    img, _ = overlay("aurora")
    l, t, r, b = CONTENT
    w, h = screen_size(r - l, b - t)
    x = (W - w) // 2
    framed(card, fill_crop(img, w, h), (x, t, x + w, t + h))
    return card


def card_words():
    card = background()
    header(card, "OPTIONAL BREAK MESSAGES", "A line for the moment.",
           "Short phrases shift with the hour, with lunar notes at new and full moon.")
    img, _ = overlay("ember")
    l, t, r, b = CONTENT
    w, h = screen_size(r - l, b - t - 190)
    x = (W - w) // 2
    # Closer in on the line itself: the middle 60% of the break screen
    cw, ch = round(img.width * 0.6), round(img.height * 0.6)
    cx, cy = (img.width - cw) // 2, (img.height - ch) // 2
    framed(card, fill_crop(img.crop((cx, cy, cx + cw, cy + ch)), w, h), (x, t, x + w, t + h))

    # More lines the generator really draws, set as captions under the screen
    lines = ["The jaw unhooks itself", "Shoulders unspooling", "Full moon pull"]
    draw = ImageDraw.Draw(card)
    caption = font("medium", 40)
    texts = [f"\u201c{line}\u201d" for line in lines]
    gap = 90
    total = sum(caption.getlength(text) for text in texts) + gap * (len(texts) - 1)
    xx, yy = (W - total) / 2, t + h + 80
    for i, text in enumerate(texts):
        draw.text((xx, yy), text, font=caption, fill=CREAM + (215,))
        xx += caption.getlength(text)
        if i < len(texts) - 1:
            draw.ellipse((xx + gap / 2 - 6, yy + 22, xx + gap / 2 + 6, yy + 34), fill=PEACH + (200,))
        xx += gap
    return card


def card_skip():
    card = background()
    header(card, "HOLD TO SKIP", "A little room to leave.",
           "Hold briefly to skip. Lock mode hides the skip control.")
    capture, _ = load(RAW / "break-skip.png")
    l, t, r, b = CONTENT
    w, h = screen_size(r - l, b - t)
    x = (W - w) // 2
    if capture is not None:
        screen = fill_crop(capture, w, h, focus=(0.5, 1.0))   # keep the bottom edge, where the ring is
        # A real capture is a Retina screen ~1440pt wide; the ring sits where the app put it
        ring_at = (w / 2, h - 92 * (w / 1440))
    else:
        src, _ = overlay("violet")
        src = src.copy()
        # The re-drawn overlays put 2880px on one point-scale (text at 56px), so the
        # ring goes in at that same scale to keep its size true to the picture
        cx, cy = draw_skip_ring(src, 0.68, pt=src.width / 2880)
        screen = fill_crop(src, w, h)
        k = w / src.width
        ring_at = (cx * k, cy * k)
    framed(card, screen, (x, t, x + w, t + h))
    ring_card = (x + ring_at[0], t + ring_at[1])
    loupe(card, screen, ring_at, 1.0, at=(round(ring_card[0] + 560), round(ring_card[1] - 250)))

    # A quiet thread from the ring to its close-up
    thread = Image.new("RGBA", card.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(thread)
    ax, ay = ring_card[0] + 560, ring_card[1] - 250
    ang = math.atan2(ay - ring_card[1], ax - ring_card[0])
    start = (ring_card[0] + 44 * math.cos(ang), ring_card[1] + 44 * math.sin(ang))
    end = (ax - 204 * math.cos(ang), ay - 204 * math.sin(ang))
    d.line([start, end], fill=CREAM + (110,), width=3)
    card.alpha_composite(thread)
    return card


def card_rhythm():
    card = background()
    header(card, "SET YOUR OWN RHYTHM", "Short breaks, your way.",
           "10 seconds to 3 minutes, every 15 minutes to 3 hours.")
    l, t, r, b = CONTENT
    gap = 48
    w = (r - l - gap * 2) // 3
    labels = [("aurora", "AURORA", "Shifts with the hour"),
              ("ember", "EMBER", "Warm all day"),
              ("violet", "VIOLET", "Cool all day")]
    for i, (theme, title, caption) in enumerate(labels):
        img, _ = overlay(theme)
        x = l + i * (w + gap)
        framed(card, fill_crop(img, w, b - t), (x, t, x + w, b), radius=30)
        label_pill(card, (x + 24, b - 24 - 112, x + w - 24, b - 24), title, caption)
    return card


def card_settings():
    capture, _ = load(RAW / "settings.png")
    if capture is None:
        return None
    card = background()
    header(card, "MAKE IT YOURS", "Your rhythm, your rules.",
           "Every 15 minutes to 3 hours, for 10 seconds to 3 minutes. Four moods. Sound or silence.")
    l, t, r, b = CONTENT
    w, h = fit_size(capture, r - l, b - t)
    x = (W - w) // 2
    framed(card, capture.resize((w, h), Image.LANCZOS), (x, t, x + w, t + h), radius=24)
    return card


def card_menubar():
    capture, _ = load(RAW / "menubar.png")
    if capture is None:
        return None
    card = background()
    header(card, "LIVES IN YOUR MENU BAR", "A heads-up before it lands.",
           "Pause and pick up right where you left off, or take a break now.")
    l, t, r, b = CONTENT
    w, h = fit_size(capture, r - l, b - t, max_scale=2.0)   # small captures: don't blow them up into blur
    x, y = (W - w) // 2, t + ((b - t) - h) // 2
    framed(card, capture.resize((w, h), Image.LANCZOS), (x, y, x + w, y + h), radius=24)
    return card


def card_private():
    card = background()
    header(card, "NO ACCOUNT  \u2022  NO TRACKING", "Private by design.",
           "One purchase. No ads, analytics, subscriptions, or network requests.")
    img, _ = overlay("ember")
    l, t, r, b = CONTENT
    w = 1560
    h = round(w * 10 / 16)
    y = t + 20
    framed(card, fill_crop(img, w, h), (l, y, l + w, y + h))

    pillars = [("Preferences stay local", "Settings and counts stay on your Mac."),
               ("Four colorways", "Surprise picks one of three palettes."),
               ("Break on your terms", "Set the interval, length, and skip control."),
               ("One purchase", "No subscription or in-app purchases.")]
    draw = ImageDraw.Draw(card)
    col_x = l + w + 110
    col_w = r - col_x
    title_font, body_font = font("bold", 44), font("medium", 32)
    blocks = [(title, wrap(body, body_font, col_w)) for title, body in pillars]
    block_h = [60 + 44 * len(lines) for _, lines in blocks]
    gap = 40
    yy = y + (h - (sum(block_h) + gap * (len(blocks) - 1))) // 2
    for (title, lines), bh in zip(blocks, block_h):
        draw.ellipse((col_x - 34, yy + 18, col_x - 16, yy + 36), fill=PEACH + (230,))
        draw.text((col_x, yy), title, font=title_font, fill=PEACH + (242,))
        for i, line in enumerate(lines):
            draw.text((col_x, yy + 60 + i * 44), line, font=body_font, fill=(235, 224, 250, 220))
        yy += bh + gap
    return card


def main():
    builders = [("break-the-spell", card_hero), ("street-smart-wisdom", card_words),
                ("hold-to-skip", card_skip), ("living-shaders", card_rhythm),
                ("make-it-yours", card_settings), ("menu-bar", card_menubar),
                ("no-subscriptions", card_private)]
    cards = [(slug, c) for slug, build in builders if (c := build()) is not None]

    OUT.mkdir(parents=True, exist_ok=True)
    for stale in OUT.glob("*.png"):
        stale.unlink()
    for n, (slug, card) in enumerate(cards, start=1):
        rgb = card.convert("RGB")   # no alpha channel in store screenshots
        for size in [(2880, 1800), (1440, 900)]:
            out = rgb if size == rgb.size else rgb.resize(size, Image.LANCZOS)
            path = OUT / f"{n:02d}-{slug}-{size[0]}x{size[1]}.png"
            out.save(path, optimize=True)
            print(f"✅ {path.relative_to(ROOT)}")

    using = "real captures" if any(RAW.glob("break-*.png")) else "re-drawn overlays (add screenshots/raw/ captures to upgrade)"
    print(f"\n✨ {len(cards)} cards from {using}")


if __name__ == "__main__":
    main()
