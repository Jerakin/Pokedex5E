from pathlib import Path
import json

Pokemon = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon.json")
output_path = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon_types.json")

new_json = {}

with open(Pokemon, "r") as fp:
    pokemon_data = json.load(fp)
    for species, data in pokemon_data.items():
        for _type in data["Type"]:
            name = _type + " Ace"
            if not _type in new_json:
                new_json[_type] = []
            new_json[_type].append(species)
    with open(output_path, "w") as f:
        json.dump(new_json, f, ensure_ascii=False, indent="  ")