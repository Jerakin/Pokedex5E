import deftree
import math
import json
from pathlib import Path
poke_num = 386

p = Path(__file__).parent.parent.parent.parent.parent / "assets/datafiles/pokemon_order.json"
out = Path(__file__).parent.parent.parent.parent.parent / "assets/sprite{}.atlas"


with open(p, "r") as f:
    data = json.load(f)
    for atlas in range(math.ceil(len(data["number"]) / 256)):
        tree = deftree.DefTree()
        root = tree.get_root()
        for i, pokemon in enumerate(data["number"]):
            num = i + 1
            atlas_num = math.floor(num / 256) + 1
            name = "/assets/textures/sprites/{}{}.png".format(num, pokemon)
            images = root.add_element("images")
            images.add_attribute("image", name)
        root.add_attribute("margin", 0)
        root.add_attribute("extrude_borders", 0)
        root.add_attribute("inner_padding", 0)
        tree.write(str(out).format(atlas))
