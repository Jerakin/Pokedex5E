from pathlib import Path
import json

habitat = Path(r"D:\Repo\Pokedex\assets\datafiles\habitat.json")
pokemons = Path(r"D:\Repo\Pokedex\assets\datafiles\pokemon_order.json")

with open(habitat, "r") as fp:
    with open(pokemons, "r") as f:
        pokemon_data = json.load(f)
        habitat_data = json.load(fp)

        for habitat, pokemon_list in habitat_data.items():
            for poke in pokemon_list:
                pokemon_data["number"].remove(poke)
        print(pokemon_data["number"])