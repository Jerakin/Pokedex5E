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
        if index in indexes or index < 721:
            continue

        raw_url = "https://bulbapedia.bulbagarden.net/wiki/File:{:03d}{}.png".format(index, pokemon)
        file_name = Path("./raw_images/{}{}.png".format(index, pokemon)).absolute()
        if not file_name.exists():
            r = requests.get(raw_url)
            url = get_url_from_source(r.content)
            if url:
                download_image(url, file_name)
            else:
                print("No Match", pokemon)
            time.sleep(0.5)


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

main()
