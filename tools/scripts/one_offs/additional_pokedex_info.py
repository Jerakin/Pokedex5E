from pathlib import Path
import json
import re

# https://github.com/PokeAPI/api-data
input_location = Path().home() / "downloads" / "api-data-master" / "data" / "api" / "v2"
output_location = Path(__file__).parent.parent.parent / "assets" / "datafiles"

output_data = {}
pokemon_index_cap = 721

for index in range(pokemon_index_cap):
    index += 1

    json_path = input_location / "pokemon" / str(index) / "index.json"
    with open(json_path, "r", encoding="utf-8") as f:
        json_data = json.load(f)
        weight_text = json_data["weight"]
        height_text = json_data["height"]
        species = json_data["name"].capitalize()

    json_path = input_location / "pokemon-species" / str(index) / "index.json"
    with open(json_path, "r", encoding="utf-8") as f:
        json_data = json.load(f)

        for flavor in json_data["flavor_text_entries"]:
            if flavor["language"]["name"] == "en" and flavor["version"]["name"] == "omega-ruby":
                flavor_text = flavor["flavor_text"].replace(species.upper(), species.capitalize()).replace("\n", " ").replace("\x0c", " ").replace("POKéMON", "Pokémon")
                break
        for genus in json_data["genera"]:
            if genus["language"]["name"] == "en":
                genus_text = genus["genus"]
                break
    output_data[index] = {"flavor": flavor_text, "height": height_text, "weight": weight_text, "genus": genus_text}

with open(output_location / "pokedex_extra.json", "w", encoding="utf-8") as f:
    json.dump(output_data, f, indent="  ", ensure_ascii=False)