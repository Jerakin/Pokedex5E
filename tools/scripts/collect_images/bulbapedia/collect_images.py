import json
import time
import requests
import shutil
import re
from pathlib import Path
p = Path(__file__).parent.parent.parent.parent.parent / "assets/datafiles/pokemon.json"

dirty_reg = re.compile("filehistory-selected[^\"]*.*?(cdn\.bulbagarden\.net/upload[^\"]*)")


def main():
    indexes = []
    with open(p, "r") as f:
        data = json.load(f)
        for pokemon, data in data.items():
            index = data["index"]
            if index in indexes or index < 650:
                continue

            raw_url = "https://bulbapedia.bulbagarden.net/wiki/File:{:03d}{}.png".format(index, pokemon)
            file_name = Path("./raw_images/{}{}.png".format(index, pokemon)).absolute()

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
    print("Got Image ", name)
    if r.status_code == 200:
        with open(name, 'wb') as f:
            r.raw.decode_content = True
            shutil.copyfileobj(r.raw, f)
            print("Image copied")
    else:
        print("Error")

main()