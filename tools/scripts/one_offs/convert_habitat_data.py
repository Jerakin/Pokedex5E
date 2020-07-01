from pathlib import Path
import json


input_path = Path("habitat.json")
output_path = Path(r"D:\Repo\Pokedex\assets\datafiles\habitat.json")
pokemon_index = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon_order.json")

index = {}


with open(pokemon_index, "r") as f:
    data = json.load(f)
    for i, p in enumerate(data["number"]):
        index[i] = p

with open(input_path, "r") as f:
    data = json.load(f)
    new_json = {}
    for habitat, pokemons in data.items():
        pokemon_list = []
        for pokemon in pokemons:
            pokemon = int(pokemon)
            if pokemon in index and index[pokemon] not in pokemon_list:
                pokemon_list.append(index[pokemon])
        new_json[habitat] = pokemon_list
    with open(output_path, "w") as fp:
        json.dump(new_json, fp, ensure_ascii=False)
