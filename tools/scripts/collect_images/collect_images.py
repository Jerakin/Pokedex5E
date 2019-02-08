import json
import time
import requests
import shutil
import re
p = r"D:\repositories\Pokedex5E\assets\datafiles\pokemon_order.json"

dirty_reg = re.compile("filehistory-selected[^\"]*.*?(cdn\.bulbagarden\.net/upload[^\"]*)")


def main():
    with open(p, "r") as f:
        data = json.load(f)
        for i, pokemon in enumerate(data["number"]):
            raw_url = "https://bulbapedia.bulbagarden.net/wiki/File:{:03d}{}.png".format(i+1, pokemon)
            file_name = "{}{}.png".format(i+1, pokemon)

            r = requests.get(raw_url)
            url = get_url_from_source(r.content)
            if url:
                download_image(url, file_name)
            time.sleep(0.5)


def get_url_from_source(source):
    m = dirty_reg.search(str(source))
    if m:
        return m.group(1)
    print("No Match")
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