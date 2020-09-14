from pathlib import Path
import json
import os

root = Path(__file__).parent.parent.parent / "assets" / "datafiles"
habitat_json = root / "habitat.json"
pokemon_folder = root / "pokemon"
pokedex_extra_json = root / "pokedex_extra.json"
pokemon_order_json = root / "pokemon_order.json"
moves_json = root / "moves.json"
tm_json = root / "move_machines.json"
abilities_json = root / "abilities.json"
feats_json = root / "feats.json"

evolve_json = root / "evolve.json"

images_path = root.parent / "textures"


def iter_pokemon_names():
    for f in pokemon_folder.iterdir():
        if f.suffix == ".json":
            yield f.stem


def get_json(name):
    with (pokemon_folder / name).with_suffix(".json").open(encoding="utf8") as f:
        data = json.load(f)
    return data


def evolve():
    with open(evolve_json, "r") as f:
        evolve_data = json.load(f)
        for species in iter_pokemon_names():
            data = get_json(species)
            if species not in evolve_data:
                print("Species {} not in evolve data".format(species))
            current = data["current_stage"]
            total = data["total_stages"]
            if current == total:
                if "into" in data:
                    print("Last stage", species)


def pokedex_order():
    order = []
    indexes = []
    for species in iter_pokemon_names():
        pokemon_data = get_json(species)
        for species, data in pokemon_data.items():
            if data["index"] not in indexes:
                indexes.append(data["index"])
                order.append(species)
    return order


def habitat():
    with open(habitat_json, "r") as fp:
        habitat_data = json.load(fp)
    pokemon_species = [x for x in iter_pokemon_names()]
    for _, list_of_pokemon in habitat_data.items():
        for pokemon in list_of_pokemon:
            if pokemon in pokemon_species:
                pokemon_species.remove(pokemon)
    print("Not in habitat")
    print(sorted(pokemon_species))


def print_habitat():
    with open(habitat_json, "r") as fp:
        habitat_data = json.load(fp)
    for hab, list_of_pokemon in habitat_data.items():
        print(hab)
        for pokemon in list_of_pokemon:
            print(pokemon)
        print('\n\n\n')


def pokedex_extra():
    with open(pokedex_extra_json, "r", encoding="utf8") as fp:
        pokedex_extra_data = json.load(fp)
    for species in iter_pokemon_names():
        pokemon_data = get_json(species)
        try:
            pokedex_extra_data[str(pokemon_data["index"])]
        except:
            print("Pokedex: Can't find", species)


def moves():
    for pokemon in iter_pokemon_names():
        data = get_json(pokemon)
        with open(moves_json, "r") as f:
            move_data = json.load(f)
            for move in data["Moves"]["Starting Moves"]:
                if move not in move_data:
                    print(pokemon, "Starting move: ", move, "Invalid")
            for level, moves in data["Moves"]["Level"].items():
                for move in moves:
                    if move not in move_data:
                        print(pokemon, "Level", level, "move: ", move, "Invalid")


def tm():
    with open(tm_json, "r") as fp:
        with open(moves_json, "r") as f:
            move_data = json.load(f)
            tm_data = json.load(fp)

            for num, move in tm_data.items():
                if not move in move_data:
                    print("Can't find TM: ", num, move)


def abilities():
    for pokemon in iter_pokemon_names():
        data = get_json(pokemon)
        with open(abilities_json, "r") as f:
            ability_data = json.load(f)
            for _, data in data.items():
                for ability in data["Abilities"]:
                    if not ability in ability_data:
                        print("Can't find ability ", ability)
                if "Hidden Ability" in data and data["Hidden Ability"] not in ability_data:
                    print("Can't find hidden ability ", data["Hidden Ability"])


def images():
    for p in iter_pokemon_names():
        data = get_json(p)
        for x in ["pokemons", "sprites"]:
            file_path = images_path / x / "{}{}.png".format(data["index"], p)
            if not os.path.exists(file_path):
                print("Can't find image: ", "{}{}.png".format(data["index"], p), "in", x)


def long_vulnerabilities():
    for p in iter_pokemon_names():
        data = get_json(p)
        length = 0
        for t in ["Vul", "Res", "Imm"]:
            if t in data:
                length = max(length, len(", ".join(data[t])))
                print(length, p, ", ".join(data[t]))
    print(length)


def remove_vulnerabilities():
    for p in iter_pokemon_names():
        data = get_json(p)
        for t in ["Vul", "Res", "Imm"]:
            if t in data:
                del data[t]


def validate_all():
    images()
    abilities()
    moves()
    pokedex_extra()
    habitat()
    evolve()


def pokemon_list():
    index_list = {}
    for species in iter_pokemon_names():
        data = get_json(species)
        index = data["index"]
        if index > 0:
            if index not in index_list:
                index_list[index] = []
            index_list[index].append(species)

    with open(root / "index_order.json", "w") as fp:
        json.dump(index_list, fp)


def split():
    for species in iter_pokemon_names():
        data = get_json(species)
        species = species.replace(" ♀", "-f")
        species = species.replace(" ♂", "-m")

        with open(pokemon_folder / (species + ".json"), "w", encoding="utf8") as fp:
            json.dump(data, fp, indent="  ", ensure_ascii=False)

print_habitat()