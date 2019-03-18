from pathlib import Path
import json


input_path = Path("trainer_classes.json")
output_path = Path(r"D:\Repo\Pokedex\assets\datafiles\trainer_classes.json")
pokemon_index = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon_order.json")
Pokemon = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon.json")
index = {}

with open(pokemon_index, "r") as f:
    data = json.load(f)
    for i, p in enumerate(data["number"]):
        index[i+1] = p

with open(input_path, "r") as f:
    data = json.load(f)
    new_json = {}
    with open(Pokemon, "r") as fp:
        pokemon_data = json.load(fp)
        for species, p_data in pokemon_data.items():
            for _type in p_data["Type"]:
                name = _type + " Ace"
                if not name in new_json:
                    print('"{}",'.format(name))
                    new_json[name] = []
                new_json[name].append(species)

    for trainer, pokemons in data.items():
        pokemon_list = []
        for pokemon in pokemons:
            pokemon = int(pokemon)
            if pokemon in index and index[pokemon] not in pokemon_list:
                pokemon_list.append(index[pokemon])
        pokemon_list.sort()
        new_json[trainer] = pokemon_list
    with open(output_path, "w") as fp:
        json.dump(new_json, fp, ensure_ascii=False, indent="  ")
