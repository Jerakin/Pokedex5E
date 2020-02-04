from pathlib import Path
import json
import re

input_location = Path(__file__).parent / "data"
output_location = Path(__file__).parent.parent.parent.parent / "assets" / "datafiles"


def get_pokemon_index(pokemon_list, pokemon):
    pokemon = pokemon.strip()
    for i, p in enumerate(pokemon_list):
        if pokemon.split(" ")[0] == p.split(" ")[0] or pokemon.lower() == p.lower():
            return i + 1
    print("Something went wrong for", pokemon)


def convert_pokemon_data(input_file):
    convert_to_int = ["AC", "Hit Dice", "HP", "WSp", "Ssp", "Fsp", "Ev", "MIN LVL FD", "Climbing Speed"]
    convert_to_float = ["SR"]
    convert_to_list = ["Skill", "Senses"]
    attributes = ["STR", "CON", "DEX", "INT", "WIS", "CHA"]
    text_to_short = {"Strength": "STR", "Constitution": "CON", "Dexterity": "DEX", "Intelligence": "INT", "Wisdom": "WIS", "Charisma": "CHA"}
    ignore = ["Ev", "Evolve Bonus", "Description 17", "Evo Stages", "Res", "Vul", "Imm"]
    reg_starting_moves = re.compile("Starting Moves: ([A-Za-z ,-12']*)")
    reg_tm_moves = re.compile("TM: (.*)")

    type_names = ["Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water",
                  "Grass", "Electric", "Psychic", "Ice", "Dragon", "Dark", "Fairy"]

    sense_names = ["Darkvision", "Tremorsense", "Truesight", "Blindsight"]

    reg_level_moves = re.compile("Level (\d+): ([A-Za-z ,-]*)")
    reg_evolve_points = re.compile("gains (\d{1,2})")
    reg_evolve_level = re.compile("level (\d{1,2})")
    reg_evolve_move = re.compile("'(.*)'")
    reg_evolve_holding = re.compile("while holding a (.*)\.")

    output_pokemon_list = []
    output_pokemon_data = {}
    output_evolve_data = {}

    with open(input_file, "r", encoding="utf8") as fp:
        try:
            file_data = json.load(fp)
        except UnicodeDecodeError as e:
            print("ERROR IN:", input_file)
            print(e)
            import sys
            sys.exit(3)
        for pokemon, _ in file_data.items():  # We are using the list of pokemons for the evolve data so
            output_pokemon_list.append(pokemon)  # need to construct that first

        for pokemon, data in file_data.items():
            output_pokemon_data[pokemon] = {"Moves": {"Level": {}}, "index": -1, "Abilities":[]}
            output_evolve_data[pokemon] = {"into": [], "current_stage":1, "total_stages": 1}

            for attribute, value in data.items():
                if not value or value == "None" or attribute in ignore:
                    continue
                if attribute == "Index Number":
                    output_pokemon_data[pokemon]["index"] = int(value)
                    continue
                elif attribute in attributes:
                    if "attributes" not in output_pokemon_data[pokemon]:
                        output_pokemon_data[pokemon]["attributes"] = {}
                    output_pokemon_data[pokemon]["attributes"][attribute] = int(value)
                    continue
                elif "with Eviolite" in attribute:
                    output_evolve_data[pokemon]["current_stage"] = int(value)
                    continue
                elif "w/o Eviolite" in attribute:
                    output_evolve_data[pokemon]["total_stages"] = int(value)
                    continue
                elif attribute == "Moves":
                    starting_moves = reg_starting_moves.match(value)
                    if starting_moves:
                        output_pokemon_data[pokemon]["Moves"]["Starting Moves"] = starting_moves.group(1).split(", ")
                    else:
                        print("No starting moves found for ", pokemon)
                    lvl_moves = reg_level_moves.findall(value)
                    if lvl_moves:
                        for level, moves in lvl_moves:
                            output_pokemon_data[pokemon]["Moves"]["Level"][level] = [x.replace(",", "") for x in moves.split(", ") if x.replace(",", "")]
                    tm_moves = reg_tm_moves.search(value)
                    if tm_moves:
                        if "EVERY TM" in value:
                            output_pokemon_data[pokemon]["Moves"]["TM"] = [int(x+1) for x in range(100)]
                        else:
                            output_pokemon_data[pokemon]["Moves"]["TM"] = [int(x) for x in re.findall(r"[0-9]+", tm_moves.group(1))]
                            [print("Too high PP: " + str(x) + " on " + pokemon) for x in output_pokemon_data[pokemon]["Moves"]["TM"] if x > 100]
                    continue
                elif "Ability" in attribute:
                    if "Hidden" in attribute:
                        output_pokemon_data[pokemon]["Hidden Ability"] = value
                        continue
                    output_pokemon_data[pokemon]["Abilities"].append(value)
                    continue
                elif attribute.startswith("ST"):
                    if "All" in value:
                        output_pokemon_data[pokemon]["saving_throws"] = attributes
                        continue
                    if "saving_throws" not in output_pokemon_data[pokemon]:
                        output_pokemon_data[pokemon]["saving_throws"] = []
                    if value in text_to_short:
                        value = text_to_short[value]
                    if value not in text_to_short and value not in attributes:
                        print(pokemon, "-", value)
                    output_pokemon_data[pokemon]["saving_throws"].append(value)
                    continue
                    
                elif attribute in convert_to_float:
                    value = float(value)
                elif attribute in convert_to_int:
                    value = int(value)
                elif attribute in convert_to_list:
                    value = value.split(", ")
                    if attribute == "Senses":
                        for sense in value:
                            sense_type, distance = sense.split(" ")
                            if sense_type not in sense_names:
                                print(pokemon, "-", sense_type)
                elif attribute == "Type":
                    value = value.split("/")
                    for t in value:
                        if t not in type_names:
                            print(pokemon, "-", t)

                elif attribute == "Evolution for sheet" and not value == "":
                    false_positive = False
                    for poke in output_pokemon_list:
                        if not poke == pokemon and " {} ".format(poke) in value:
                            output_evolve_data[pokemon]["into"].append(poke)
                    match = reg_evolve_points.search(value)
                    if match:
                        output_evolve_data[pokemon]["points"] = int(match.group(1))

                    match = reg_evolve_level.search(value)
                    if match:
                        output_evolve_data[pokemon]["level"] = int(match.group(1))
                    else:
                        output_evolve_data[pokemon]["level"] = 0
                        match = reg_evolve_move.search(value)
                        if match:
                            output_evolve_data[pokemon]["move"] = match.group(1)
                        else:
                            match = reg_evolve_holding.search(value)
                            if match:
                                output_evolve_data[pokemon]["holding"] = match.group(1)
                            else:
                                false_positive = True
                    if false_positive:
                        output_evolve_data.pop(pokemon, None)
                    continue
                output_pokemon_data[pokemon][attribute] = value
            if pokemon in output_evolve_data and len(output_evolve_data[pokemon]["into"]) == 0:
                del output_evolve_data[pokemon]["into"]


        with open(output_location / "pokemon.json", "w", encoding="utf8") as f:
            json.dump(output_pokemon_data, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "pokemon.json"))

        with open(output_location / "evolve.json", "w", encoding="utf8") as f:
            json.dump(output_evolve_data, f, indent="  ", ensure_ascii=False)
            print("Exported {}".format(output_location / "evolve.json"))


def convert_move_data(input_file):
    convert_to_int = ["PP"]
    ignore = ["Higher Levels"]
    reg_damage_level = re.compile("Dmg lvl (\d+)")
    reg_damage_dice = re.compile("(?i)(?:(\d)x|X|)(\d+|)d(\d+)\s*(\+\s*move|)(?:\+\s*(\d)|)(\+\s*level|)")
    healing = re.compile(r"((?:re|\b)gain.\b.*hit points)")
    reg_saving_throw = re.compile("(?:(?:make|with|succeed on) a (.{3}) sav)")
    is_attack = re.compile("(?:melee|ranged) attack")
    converted = {}

    with open(input_file, "r") as fp:
        file_data = json.load(fp)
        for move, data in file_data.items():
            converted[move] = {}
            is_healing_move = False
            for attribute, value in data.items():
                if not value or value == "None" or attribute in ignore:
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
                        amount = damage.group(2)
                        amount = 0 if amount == "" else amount
                        dice_max = damage.group(3)
                        add_move = True if damage.group(4) else False
                        add_move = add_move and not is_healing_move
                        dice = {"amount": int(amount), "dice_max": int(dice_max), "move": add_move}
                        times = damage.group(1)
                        modifier = damage.group(5)
                        level_modifier = damage.group(6)
                        if modifier:
                            dice["modifier"] = int(modifier)
                        if times:
                            dice["times"] = int(times)
                        if level_modifier:
                            dice["level"] = True
                        if "Damage" not in converted[move]:
                            converted[move]["Damage"] = {}
                        converted[move]["Damage"][str(level)] = dice
                    continue
                if attribute == "Description":
                    saving_throw = reg_saving_throw.search(value)
                    if saving_throw:
                        converted[move]["Save"] = saving_throw.group(1)

                    is_healing = healing.search(value)
                    if is_healing:
                        is_healing_move = True

                    is_damage = is_attack.search(value)
                    if is_damage:
                        converted[move]["atk"] = True
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

data_sheets = {
    "IDATA.json": convert_item_data,
    "MDATA.json": convert_move_data,
    "PDATA.json": convert_pokemon_data,
    "TDATA.json": convert_ability_data
}


def main():
    for data_file in input_location.iterdir():
        if data_file.name in data_sheets:
            data_sheets[data_file.name](data_file)

if __name__ == '__main__':
    main()
