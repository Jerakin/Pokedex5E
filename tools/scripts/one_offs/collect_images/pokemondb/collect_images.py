import json
import time
import requests
import shutil
from pathlib import Path
from PIL import Image
pokemon_folder = Path(__file__).parent.parent.parent.parent.parent.parent / "assets/datafiles/pokemon"


def main():
    indexes = []
    for p_path in pokemon_folder.iterdir():
        pokemon = p_path.stem
        with p_path.open("r") as f:
            data = json.load(f)
        index = data["index"]

        if "variant_data" in data and "variants" in data["variant_data"]:
            for v_name,v_data in  data["variant_data"]["variants"].items():
                spec = v_data["original_species"]
                if spec and spec != pokemon:
                    raw_url = "https://img.pokemondb.net/sprites/sun-moon/icon/{}-{}.png".format(pokemon.lower(), v_name.lower().replace("form", "").replace("style", "").strip().replace(" ", "-").replace("'", ""))
                    if "Alol" in v_name:
                        file_name = "images/{}{}n {}.png".format(index, v_name, pokemon)
                        raw_url = "https://img.pokemondb.net/sprites/sun-moon/icon/{}-{}n.png".format(pokemon.lower(),
                                                                                                     v_name.lower().replace(
                                                                                                         "form",
                                                                                                         "").replace(
                                                                                                         "style",
                                                                                                         "").strip().replace(
                                                                                                         " ",
                                                                                                         "-").replace(
                                                                                                         "'", ""))

                        download_image(raw_url, file_name)
                        time.sleep(0.5)


def download_image(url, name):
    r = requests.get(url, stream=True)
    if r.status_code == 200:
        with open(name, 'wb') as f:
            r.raw.decode_content = True
            shutil.copyfileobj(r.raw, f)
    else:
        print("Error ", url)


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
