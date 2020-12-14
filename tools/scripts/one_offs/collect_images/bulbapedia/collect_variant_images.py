import json
import time
import requests
import shutil
import re
from pathlib import Path
p = Path(__file__).parent.parent.parent.parent.parent / "assets/datafiles/pokemon.json"
pokemon_folder = Path(__file__).parent.parent.parent.parent.parent.parent / "assets/datafiles/pokemon"


dirty_reg = re.compile("filehistory-selected[^\"]*.*?(cdn\.bulbagarden\.net/upload[^\"]*)")


def main():
    indexes = []
    for p_path in pokemon_folder.iterdir():
        pokemon = p_path.stem
        with p_path.open("r") as f:
            data = json.load(f)
        index = data["index"]

        # retrieve_image_for_pokemon(index, pokemon, None)

        if "variant_data" in data and "variants" in data["variant_data"]:
            for v_name,v_data in  data["variant_data"]["variants"].items():
                spec = v_data["original_species"]
                if spec and spec != pokemon:
                    retrieve_image_for_pokemon(index, "{}-{}".format(pokemon, v_name), spec)

def get_url_from_source(source):
    m = dirty_reg.search(str(source))
    if m:
        return m.group(1)

    return None


def download_image(url, name):
    r = requests.get("http://" + url, stream=True)
    if r.status_code == 200:
        with open(name, 'wb') as f:
            r.raw.decode_content = True
            shutil.copyfileobj(r.raw, f)
    else:
        print("Error")
        
def retrieve_image_for_pokemon(index, name, override_name):
    raw_url = "https://bulbapedia.bulbagarden.net/wiki/File:{:03d}{}.png".format(index, name)
    file_name = Path("./raw_images/{}{}.png".format(index, override_name or name)).absolute()
    if not file_name.exists():
        r = requests.get(raw_url)
        url = get_url_from_source(r.content)
        if url:
            download_image(url, file_name)
        else:
            print("No Match", name)
        time.sleep(0.5)


main()
