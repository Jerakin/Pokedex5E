import deftree
import math
import json
poke_num = 386

p = r"D:\repositories\Pokedex5E\assets\datafiles\pokemon_order.json"

out = r"D:\repositories\Pokedex5E\assets\pokemon{}.atlas"

with open(p, "r") as f:
    data = json.load(f)
    for atlas in range(math.ceil(len(data["number"]) / 256)):
        tree = deftree.DefTree()
        root = tree.get_root()
        for i, pokemon in enumerate(data["number"]):
            num = i + 1
            atlas_num = math.floor(num / 256) + 1
            name = "/assets/textures/pokemon/{}{}.png".format(num, pokemon)
            images = root.add_element("images")
            images.add_attribute("image", name)
        root.add_attribute("margin", 0)
        root.add_attribute("extrude_borders", 0)
        root.add_attribute("inner_padding", 0)
        tree.write(out.format(atlas))
