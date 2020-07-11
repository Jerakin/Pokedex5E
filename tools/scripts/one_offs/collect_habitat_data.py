from pathlib import Path
import json
import re
import requests

output_path = Path(r"D:\Repo\Pokedex\assets\datafiles\habitat.json")

dirty_reg = re.compile('title="(\d{3})"><img alt="\d{3}"')

output = {}

def main():
    pokemon_list = []
    raw_url = "https://bulbapedia.bulbagarden.net/wiki/User:NikNaks/Pok%C3%A9mon_by_habitat"
    try:
        r = requests.get(raw_url)
        for m in re.findall(dirty_reg, str(r.content)):
            pokemon_list.append(m)

        with open(output_path, "w") as fp:
            output["list"] = pokemon_list
            json.dump(output, fp)
        print(pokemon_list)
    except:
        pass



main()
