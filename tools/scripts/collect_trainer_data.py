from pathlib import Path
import json
import re
import requests

input_path = Path(r"D:\Repo\Pokedex\assets\datafiles\trainer_class_list.json")
output_path = Path(r"D:\Repo\Pokedex\assets\datafiles\trainer_class.json")

dirty_reg = re.compile('title="(\d{3})"><img alt="\d{3}"')

new_json = {}

def main():
    with open(input_path, "r+") as f:
        data = json.load(f)
        for trainer in data["Classes"]:
            raw_url = "https://m.bulbapedia.bulbagarden.net/wiki/{}_(Trainer_class)".format(trainer.replace(" ", "_"))
            new_json[trainer] = []
            try:
                r = requests.get(raw_url)
                for m in re.findall(dirty_reg, str(r.content)):
                    new_json[trainer].append(m)
            except:
                print(trainer)
                pass

        with open(output_path, "w") as fp:
            json.dump(new_json, fp)


main()
