from pathlib import Path
import json

Pokemon = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon.json")

new_doc = {}

with open(Pokemon, "r") as fp:
    pokemon_data = json.load(fp)
    for species, data in pokemon_data.items():
        for _type in data["Type"]:
            name = _type + " Ace"
            if not name in new_doc:
                new_doc[name] = []
            new_doc[name].append(species)
    for trainer, _ in new_doc.items():
        print('"{}",'.format(trainer))
print(new_doc)