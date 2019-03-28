import json
import time
import requests
import shutil
from pathlib import Path

p = Path(__file__).parent.parent.parent.parent.parent / "assets/datafiles/pokemon_numbers.json"

def main():
    with open(p, "r") as f:
        data = json.load(f)
        for i, pokemon in enumerate(data["number"]):
            if i < 385:
                continue
            # raw_url = "https://img.pokemondb.net/sprites/omega-ruby-alpha-sapphire/dex/normal/{}.png".format(pokemon.lower())
            # raw_url = "https://img.pokemondb.net/sprites/x-y/normal/{}.png".format(pokemon.lower())
            raw_url = "https://img.pokemondb.net/sprites/sun-moon/icon/{}.png".format(pokemon.lower())

            file_name = "images/{}{}.png".format(i+1, pokemon)
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

main()