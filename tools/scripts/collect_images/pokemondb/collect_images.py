import json
import time
import requests
import shutil
from pathlib import Path
from PIL import Image
p = Path(__file__).parent.parent.parent.parent.parent / "assets/datafiles/pokemon.json"


def main():
    indexes = []
    with open(p, "r") as f:
        data = json.load(f)
        for pokemon, data in data.items():
            index = data["index"]
            if index in indexes or index < 649:
                continue

            indexes.append(index)
            # raw_url = "https://img.pokemondb.net/sprites/omega-ruby-alpha-sapphire/dex/normal/{}.png".format(pokemon.lower())
            # raw_url = "https://img.pokemondb.net/sprites/x-y/normal/{}.png".format(pokemon.lower())
            print("Downloading", pokemon)
            raw_url = "https://img.pokemondb.net/sprites/sun-moon/icon/{}.png".format(pokemon.lower())

            file_name = "images/{}{}.png".format(index, pokemon)
            download_image(raw_url, file_name)
            time.sleep(0.5)


def download_image(url, name):
    r = requests.get(url, stream=True)
    if r.status_code == 200:
        with open(name, 'wb') as f:
            r.raw.decode_content = True
            shutil.copyfileobj(r.raw, f)
    else:
        print("Error ", name)


def convert(path):
    for i in path.iterdir():
        if i.suffix == ".png":
            im = Image.open(i)
            if im.mode == "P":
                im.convert("RGBA").save(i)
            else:
                print(im.mode)


# convert(Path(__file__).parent.parent.parent.parent.parent / "assets" / "textures" / "sprites")

main()
