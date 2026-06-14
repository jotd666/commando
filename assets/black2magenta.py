from PIL import Image,ImageOps
import pathlib

# MAME gfx save edition is cool but cannot differentiate background color from black.
# this is pretty f**ing annoying, fortunately, there's always a CLUT in the set which makes the difference
# here it's monochrome palette index 0xD that saves us.

# here there's actually no problem, as there are no real black color used for sprites
# dark colors are (0,17,0) and (17,0,17)

this_dir = pathlib.Path(__file__).absolute().parent

src_sprite_dir = this_dir / "sheets" / "fg_tiles_black"
dst_sprite_dir = this_dir / "sheets" / "fg_tiles"

red_image = Image.open(src_sprite_dir / "pal_07.png")

red_pixels = set()

# this palette has the nice property of having black not merged with background
# black colors in other palettes are there red, so we can backport the black color in other palettes
for x in range(red_image.size[0]):
    for y in range(red_image.size[1]):
        p = red_image.getpixel((x,y))
        if p == (67,67,112):
            red_pixels.add((x,y))

for i in range(16):
    imgname = f"pal_{i:02X}.png"
    src = src_sprite_dir / imgname
    dst = dst_sprite_dir / imgname

    src_image = Image.open(src)
    dst_image = Image.new("RGB",red_image.size)
    for x in range(red_image.size[0]):
        for y in range(red_image.size[1]):
            p = src_image.getpixel((x,y))
            if p == (0,0,0):
                # black: what do do?
                if (x,y) in red_pixels:
                    pass
                else:
                    p = (254,0,254)  # black => magenta but not full magenta to avoid conflicts
            dst_image.putpixel((x,y),p)

    dst_image.save(dst)
