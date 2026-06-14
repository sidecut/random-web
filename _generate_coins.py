#!/usr/bin/env python3
"""Generate photorealistic coin face images for heads and tails."""

import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 512
R = SIZE // 2
CX, CY = R, R

def metallic_gradient(draw, r):
    """Draw a metallic radial gradient base."""
    for i in range(r, 0, -1):
        # Silver-gold metallic tones
        t = i / r
        # Base: warm silver
        r_component = int(180 + 40 * t + 15 * (1 - t))
        g_component = int(165 + 50 * t + 20 * (1 - t))
        b_component = int(140 + 55 * t + 25 * (1 - t))
        color = (r_component, g_component, b_component)
        draw.ellipse(
            [CX - i, CY - i, CX + i, CY + i],
            fill=color
        )

def draw_rim(draw, r):
    """Draw darker raised rim."""
    rim_width = r // 25
    for i in range(rim_width, 0, -1):
        t = i / rim_width
        brightness = int(80 + 40 * t)
        color = (brightness, brightness - 10, brightness - 20)
        draw.ellipse(
            [CX - r + i, CY - r + i, CX + r - i, CY + r - i],
            outline=color, width=2
        )
    # Inner rim highlight
    draw.ellipse(
        [CX - r + rim_width + 2, CY - r + rim_width + 2,
         CX + r - rim_width - 2, CY + r - rim_width - 2],
        outline=(200, 190, 170), width=1
    )

def draw_dots_ring(draw, r, count=60):
    """Draw ring of dots near the rim."""
    dot_r = r - r // 7
    dot_size = r // 60
    for i in range(count):
        angle = 2 * math.pi * i / count
        x = CX + dot_r * math.cos(angle)
        y = CY + dot_r * math.sin(angle)
        draw.ellipse(
            [x - dot_size, y - dot_size, x + dot_size, y + dot_size],
            fill=(60, 50, 40)
        )

def draw_specular(draw, r):
    """Draw a subtle glossy sheen for 3D effect."""
    center_x = CX - r * 0.15
    center_y = CY - r * 0.15
    max_i = int(r * 0.18)
    for i in range(max_i, 0, -1):
        t = i / max_i
        # Very faint, fades to transparent quickly
        alpha = int(12 * t * t * t)
        base = 210
        draw.ellipse(
            [center_x - i, center_y - i, center_x + i, center_y + i],
            fill=(base + alpha, base + alpha - 5, base + alpha - 15)
        )

def draw_profile(draw, r):
    """Draw a profile silhouette (George Washington style)."""
    inner_r = r * 0.65
    cx, cy = CX, CY - r * 0.02
    
    # Simplified profile silhouette
    # Head shape
    draw.ellipse(
        [cx - inner_r * 0.4, cy - inner_r * 0.6,
         cx + inner_r * 0.5, cy + inner_r * 0.5],
        fill=(55, 45, 35)
    )
    # Neck/shoulders
    draw.rectangle(
        [cx - inner_r * 0.15, cy + inner_r * 0.1,
         cx + inner_r * 0.35, cy + inner_r * 0.7],
        fill=(55, 45, 35)
    )
    # Hair detail - ponytail
    draw.ellipse(
        [cx + inner_r * 0.2, cy - inner_r * 0.4,
         cx + inner_r * 0.55, cy - inner_r * 0.1],
        fill=(40, 32, 25)
    )
    # Nose
    draw.ellipse(
        [cx + inner_r * 0.32, cy - inner_r * 0.05,
         cx + inner_r * 0.48, cy + inner_r * 0.08],
        fill=(70, 58, 45)
    )
    # Eye
    draw.ellipse(
        [cx + inner_r * 0.15, cy - inner_r * 0.2,
         cx + inner_r * 0.25, cy - inner_r * 0.12],
        fill=(30, 24, 18)
    )

def draw_eagle(draw, r):
    """Draw an eagle/heraldic design for tails."""
    inner_r = r * 0.55
    cx, cy = CX, CY - r * 0.03
    
    # Body
    draw.ellipse(
        [cx - inner_r * 0.3, cy - inner_r * 0.25,
         cx + inner_r * 0.3, cy + inner_r * 0.4],
        fill=(55, 45, 35)
    )
    # Head
    draw.ellipse(
        [cx - inner_r * 0.2, cy - inner_r * 0.55,
         cx + inner_r * 0.2, cy - inner_r * 0.15],
        fill=(55, 45, 35)
    )
    # Left wing - spread
    draw.polygon([
        (cx - inner_r * 0.3, cy - inner_r * 0.15),
        (cx - inner_r * 0.85, cy - inner_r * 0.5),
        (cx - inner_r * 0.75, cy),
        (cx - inner_r * 0.3, cy + inner_r * 0.1),
    ], fill=(55, 45, 35))
    # Right wing - spread
    draw.polygon([
        (cx + inner_r * 0.3, cy - inner_r * 0.15),
        (cx + inner_r * 0.85, cy - inner_r * 0.5),
        (cx + inner_r * 0.75, cy),
        (cx + inner_r * 0.3, cy + inner_r * 0.1),
    ], fill=(55, 45, 35))
    # Beak
    draw.polygon([
        (cx + inner_r * 0.15, cy - inner_r * 0.45),
        (cx + inner_r * 0.35, cy - inner_r * 0.35),
        (cx + inner_r * 0.15, cy - inner_r * 0.28),
    ], fill=(80, 65, 40))
    # Eye
    draw.ellipse(
        [cx + inner_r * 0.05, cy - inner_r * 0.42,
         cx + inner_r * 0.13, cy - inner_r * 0.35],
        fill=(30, 24, 18)
    )
    # Talons
    for offset in [-inner_r * 0.25, inner_r * 0.25]:
        draw.ellipse(
            [cx + offset - inner_r * 0.12, cy + inner_r * 0.35,
             cx + offset + inner_r * 0.12, cy + inner_r * 0.55],
            fill=(70, 55, 40)
        )

def draw_stars(draw, r, count=13):
    """Draw small stars around the edge (like on real coins)."""
    star_r = r * 0.72
    star_size = r // 40
    for i in range(count):
        angle = 2 * math.pi * i / count - math.pi / 2
        sx = CX + star_r * math.cos(angle)
        sy = CY + star_r * math.sin(angle)
        # Simple 5-pointed star
        pts = []
        for j in range(5):
            outer_angle = angle + 2 * math.pi * j / 5
            inner_angle = angle + 2 * math.pi * (j + 0.5) / 5
            pts.append((sx + star_size * math.cos(outer_angle),
                        sy + star_size * math.sin(outer_angle)))
            pts.append((sx + star_size * 0.4 * math.cos(inner_angle),
                        sy + star_size * 0.4 * math.sin(inner_angle)))
        draw.polygon(pts, fill=(50, 42, 32))

def draw_text_ring(draw, r, text, font_size=28):
    """Draw text along the top arc."""
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        font = ImageFont.load_default()
    
    # Draw letters along arc
    arc_radius = r * 0.75
    total_angle = math.radians(100)
    start_angle = math.pi / 2 + total_angle / 2
    char_spacing = total_angle / (len(text) - 1) if len(text) > 1 else 0
    
    for i, char in enumerate(text):
        angle = start_angle - i * char_spacing
        x = CX + arc_radius * math.cos(angle)
        y = CY - arc_radius * math.sin(angle)
        # Create small text image and rotate
        tmp = Image.new('RGBA', (40, 40), (0, 0, 0, 0))
        tmp_draw = ImageDraw.Draw(tmp)
        tmp_draw.text((5, 5), char, fill=(40, 32, 25), font=font)
        rotated = tmp.rotate(math.degrees(angle - math.pi/2), expand=True, resample=Image.BICUBIC)
        draw._image.paste(rotated, (int(x - rotated.width/2), int(y - rotated.height/2)), rotated)

def make_coin(design, text, filename):
    """Generate a coin image with given design and text."""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Base metallic gradient
    metallic_gradient(draw, R)
    
    # Outer rim
    draw_rim(draw, R)
    
    # Dots ring
    draw_dots_ring(draw, R)
    
    # Text around edge
    draw_text_ring(draw, R, text, font_size=26)
    
    # Main design
    design(draw, R)
    
    # Stars
    draw_stars(draw, R)
    
    # Specular highlight on top
    draw_specular(draw, R)
    
    # Smooth the result slightly
    img = img.filter(ImageFilter.GaussianBlur(radius=0.5))
    
    img.save(filename)
    print(f"Saved {filename}")

if __name__ == "__main__":
    make_coin(draw_profile, "LIBERTY", "images/heads.png")
    make_coin(draw_eagle, "UNITED STATES OF AMERICA", "images/tails.png")
    print("Done!")
