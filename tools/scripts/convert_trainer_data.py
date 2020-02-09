from pathlib import Path
import json


input_path = Path("trainer_classes.json")
root = Path(__file__).parent.parent.parent
pokemon = root / "assets/datafiles/filter_data.json"

output_path = root / r"assets"/ "datafiles" / "trainer_classes.json"

pokemon_index = {}

with open(pokemon, "r") as f:
    data = json.load(f)
    for species, data in data.items():
        if data["index"] not in pokemon_index:
            pokemon_index[data["index"]] = []

        pokemon_index[data["index"]].append(species)

with open(input_path, "r") as f:
    data = json.load(f)
    new_json = {}

    for trainer, pokemons in data.items():
        pokemon_list = []
        for index in pokemons:
            if index in pokemon_index:
                pokemon_list.extend(pokemon_index[index])

        pokemon_list.sort()
        new_json[trainer] = pokemon_list
    with open(output_path, "w") as fp:
        json.dump(new_json, fp, ensure_ascii=False, indent="  ")
