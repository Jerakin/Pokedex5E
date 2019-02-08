from PIL import Image
import os
from pathlib import Path


size = 128, 128
p = Path(__file__).parent / "raw_images"
out = Path(__file__).parent / "resized"

for infile in p.iterdir():
    outfile = out / infile.name
    if infile != outfile:
        try:
            img = Image.open(infile)
            img.thumbnail(size, Image.ANTIALIAS)
            img.save(outfile, "PNG")
        except IOError:
            print("cannot create thumbnail for '%s'" % infile)
