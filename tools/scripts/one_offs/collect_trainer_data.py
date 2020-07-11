from pathlib import Path
import json
import re
import requests
from codecs import open

input_path = Path("trainer_classes_list.json")
output_path = Path(r"trainer_classes.json")

dirty_reg = re.compile('title="(\d{3})"><img alt="\d{3}"')

new_json = {}

trainer_list = ["Ace Trainer", "Janitor", "Backpacker", "Delinquent", "Street Thug", "Team Skull Grunt", "Beauty",
                "Pokémon Breeder", "Bird Keeper", "Blackbelt", "Bug Catcher", "Burglar", "Channeler", "Roughneck",
                "Engineer", "Fisherman", "Gamer", "Gentleman", "Hiker", "Juggler", "Psychic", "Rocker", "Sailor",
                "Scientist", "Super Nerd", "Tamer", "Youngster", "Firebreather", "Ruin Maniac", "Veteran", "Swimmer",
                "Poké Fan", "Aroma Lady", "Hex Maniac"]


def clean_content(content):
    pre_removed = content.split('id="Trainer_list">Trainer list', 1)[-1]
    post_removed = pre_removed.split('''mon Stadium</span></h3>''')[0]
    return post_removed


def main():
    for trainer in trainer_list:
        raw_url = "https://m.bulbapedia.bulbagarden.net/wiki/{}_(Trainer_class)".format(trainer.replace(" ", "_"))
        print(trainer)

        new_json[trainer] = []
        r = requests.get(raw_url)
        for m in re.findall(dirty_reg, clean_content(str(r.content))):
            index = int(m)
            if index not in new_json[trainer]:
                new_json[trainer].append(index)

    for trainer, p_list in new_json.items():
        p_list.sort()

    with open(output_path, "w") as fp:
        json.dump(new_json, fp, ensure_ascii=False)

main()
