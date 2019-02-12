from pathlib import Path
import json
import re

input_location = Path(__file__).parent / "data"
output_location = Path(__file__).parent.parent.parent.parent / "assets" / "datafiles"


def convert_pokemon_data(input_file):
    convert_to_int = ["AC", "Hit Dice", "HP", "WSp", "Ssp", "Fsp", "Ev", "MIN LVL FD"]
    convert_to_float = ["CR"]
    convert_to_list = ["Skill", "Res", "Vul", "Imm"]
    attributes = ["STR", "CON", "DEX", "INT", "WIS", "CHA"]
    reg_starting_moves = re.compile("Starting Moves: ([A-Za-z ,-]*)")
    reg_abilities = re.compile("Abilities: ([A-Za-z, ]*)")
    reg_level_moves = re.compile("Level (\d+): ([A-Za-z ,-]*)")
    reg_evolve_points = re.compile(".* gains (\d{1,2})")
    reg_evolve_level = re.compile("level (\d{1,2})")

    output_pokemon_data = {}
    output_pokemon_list = []
    output_evolve_data = {}
    with open(input_file, "r") as fp:
        file_data = json.load(fp)
        for pokemon, _ in file_data.items():     # We are using the list of pokemons for the evolve data so
            output_pokemon_list.append(pokemon)  # need to construct that first
        pokemon_index = 0
        for pokemon, data in file_data.items():
            pokemon_index += 1
            output_pokemon_data[pokemon] = {"Moves": {"Level": {}}, "index": pokemon_index}

            for attribute, value in data.items():
                if not value:
                    continue

                if attribute in attributes:
                    if "attributes" not in output_pokemon_data[pokemon]:
                        output_pokemon_data[pokemon]["attributes"] = {}
                    output_pokemon_data[pokemon]["attributes"][attribute] = int(value)
                    continue
                if attribute == "Moves":
                    starting_moves = reg_starting_moves.match(value)
                    if starting_moves:
                        output_pokemon_data[pokemon]["Moves"]["Starting Moves"] = starting_moves.group(1).split(", ")
                    else:
                        print("No starting moves found for ", pokemon)
                    lvl_moves = reg_level_moves.search(value)
                    if lvl_moves:
                        level = lvl_moves.group(1)
                        moves = lvl_moves.group(2).split(", ")
                        output_pokemon_data[pokemon]["Moves"]["Level"][level] = moves
                    abilities = reg_abilities.search(value)
                    if abilities:
                        output_pokemon_data[pokemon]["Abilities"] = abilities.group(1).split(", ")
                    continue
                if attribute.startswith("ST"):
                    if "saving_throws" not in output_pokemon_data[pokemon]:
                        output_pokemon_data[pokemon]["saving_throws"] = []
                    output_pokemon_data[pokemon]["saving_throws"].append(value)
                    continue
                    
                if attribute in convert_to_float:
                    value = float(value)
                elif attribute in convert_to_int:
                    value = int(value)
                elif attribute in convert_to_list:
                    value = value.split(", ")

                elif attribute == "Type":
                    value = value.split("/")

                if attribute == "Evolution for sheet" and not value == "":
                    output_evolve_data[pokemon] = {"into": [], "points": 0}
                    for poke in output_pokemon_list:
                        if not poke == pokemon and " {} ".format(poke) in value:
                            output_evolve_data[pokemon]["into"].append(poke)
                    output_evolve_data[pokemon]["points"] = int(reg_evolve_points.search(value).group(1))
                    output_evolve_data[pokemon]["level"] = int(reg_evolve_level.search(value).group(1))
                    continue
                output_pokemon_data[pokemon][attribute] = value

        with open(output_location / "pokemon_order.json", "w") as f:
            json.dump({"number": output_pokemon_list}, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "pokemon_order.json"))

        with open(output_location / "pokemon.json", "w") as f:
            json.dump(output_pokemon_data, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "pokemon.json"))

        with open(output_location / "evolve.json", "w") as f:
            json.dump(output_evolve_data, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "evolve.json"))


def convert_move_data(input_file):
    convert_to_int = ["PP"]

    reg_damage_level = re.compile("Dmg lvl (\d+)")
    reg_damage_dice = re.compile("(\d+)d(\d+)(\+Move|)")
    reg_saving_throw = re.compile("make a (.{3}) sav")
    converted = {}

    with open(input_file, "r") as fp:
        file_data = json.load(fp)
        for move, data in file_data.items():
            converted[move] = {}
            for attribute, value in data.items():
                if not value:
                    continue
                if attribute in convert_to_int:
                    try:
                        value = int(value)
                    except ValueError:
                        pass
                if attribute == "Move Power":
                    value = value.split("/")
                if attribute.startswith("Dmg"):
                    level = reg_damage_level.search(attribute).group(1)
                    damage = reg_damage_dice.search(value)
                    if damage:
                        amount = damage.group(1)
                        dice_max = damage.group(2)
                        add_move = True if damage.group(3) else False
                        dice = {"amount": int(amount), "dice_max": int(dice_max), "move": add_move}
                        if not "Damage" in converted[move]:
                            converted[move]["Damage"] = {}
                        converted[move]["Damage"][str(level)] = dice
                    continue
                if attribute == "Description":
                    saving_throw = reg_saving_throw.search(value)

                    if saving_throw:
                        converted[move]["Save"] = saving_throw.group(1)
                converted[move][attribute] = value

        with open(output_location / "moves.json", "w") as f:
            json.dump(converted, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "moves.json"))


def convert_item_data(input_file):
    with open(input_file, "r") as fp:
        file_data = json.load(fp)
        with open(output_location / "items.json", "w") as f:
            json.dump(file_data, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "items.json"))


def convert_ability_data(input_file):
    with open(input_file, "r") as fp:
        file_data = json.load(fp)
        with open(output_location / "abilities.json", "w") as f:
            json.dump(file_data, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "abilities.json"))

data_sheets = {"IDATA.json": convert_item_data,
               "MDATA.json": convert_move_data,
               "PDATA.json": convert_pokemon_data,
               "TDATA.json": convert_ability_data}


def main():
    for data_file in input_location.iterdir():
        data_sheets[data_file.name](data_file)

if __name__ == '__main__':
    main()
