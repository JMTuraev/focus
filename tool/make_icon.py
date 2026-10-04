"""Draws the Focus logo (same shapes as FokusLogo in lib/ui/title_bar.dart)
into windows/runner/resources/app_icon.ico.

    python tool/make_icon.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

BRAND = (0x33, 0x90, 0xEC, 255)
WHITE = (255, 255, 255, 255)
BIG = 1024


def logo(size: int) -> Image.Image:
    img = Image.new('RGBA', (BIG, BIG), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, BIG - 1, BIG - 1), radius=int(BIG * 0.3), fill=BRAND)
    c = BIG / 2
    ring_r = BIG * 0.25
    stroke = BIG * 0.09
    outer = ring_r + stroke / 2
    d.ellipse((c - outer, c - outer, c + outer, c + outer), fill=WHITE)
    inner = ring_r - stroke / 2
    d.ellipse((c - inner, c - inner, c + inner, c + inner), fill=BRAND)
    dot = BIG * 0.085
    d.ellipse((c - dot, c - dot, c + dot, c + dot), fill=WHITE)
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    out = Path(__file__).resolve().parent.parent / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
    sizes = [16, 20, 24, 32, 40, 48, 64, 128, 256]
    logo(256).save(out, format='ICO', sizes=[(s, s) for s in sizes])
    print(f'written {out.name}: {out.stat().st_size} bytes')


if __name__ == '__main__':
    main()
