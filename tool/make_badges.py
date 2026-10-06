"""Generates the taskbar overlay badges (assets/badge/1.ico … 9.ico, more.ico):
a red circle with a white number, like Telegram's unread badge.
Run once after changing the look:  python tool/make_badges.py
"""
from PIL import Image, ImageDraw, ImageFont

SIZES = [16, 20, 24, 32, 48]
RED = (229, 57, 53, 255)

def render(label: str, size: int) -> Image.Image:
    scale = 8
    big = size * scale
    img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 0, big - 1, big - 1], fill=RED)
    font = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', int(big * (0.72 if len(label) == 1 else 0.6)))
    box = d.textbbox((0, 0), label, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((big - w) / 2 - box[0], (big - h) / 2 - box[1] - big * 0.02), label, font=font, fill='white')
    return img.resize((size, size), Image.LANCZOS)

for label, name in [*((str(n), str(n)) for n in range(1, 10)), ('9+', 'more')]:
    frames = [render(label, s) for s in SIZES]
    frames[-1].save(f'assets/badge/{name}.ico', format='ICO', sizes=[(s, s) for s in SIZES],
                    append_images=frames[:-1])
print('ok')
