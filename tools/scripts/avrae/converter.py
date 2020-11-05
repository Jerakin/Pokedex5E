from pathlib import Path
import json

root = Path(__file__).parent.parent.parent.parent
output = Path(__file__).parent / "output"


json_item_example = {"name": "Potion", "meta": "Restorative",
                     "desc": "Restores a creatures HP by 2d4+2\n\nCosts: 200 Pokedollars\n\nGen 1"}

json_move_scaling_example = {"name": "Absorb", "meta": "**Type:** Grass\n**Move Power:** STR/DEX\n**Move Time:** 1 action\n**PP:** 15\n**Duration:** Instantaneous\n**Range:** Melee", "desc": "You attempt to absorb some of an enemy’s health. Make a melee attack on a Pokémon. On a hit, the Pokémon takes 1d6 + MOVE grass damage. Half the damage done is restored by the user.\n\n**Higher Levels:** The damage dice roll for this move changes to 1d12 at level 5, 2d8 at level 10, and 4d6 at level 17."}

json_move_example = {"name": "Fake Tears", "meta": "**Type:** Dark\n**Move Power:** WIS/CHA\n**Move Time:** 1 action\n**PP:** 5\n**Duration:** Instantaneous\n**Range:** 50ft.","desc":"You fake an opponent out with superficial tears, lowering their defenses. When activating this move, a target must make a WIS saving throw against your Move DC. On a failure, all attack rolls against the target are given a +5 bonus until the end of your next turn."}

json_extra_example = {"name": "Weak Armor", "meta": "Ability", "desc": "When an attack hits this Pokémon, its speed increases by 5 feet, but its AC is temporarily reduced by 1 until the end of battle (for a maximum reduction of -5)."}


def convert_moves():
    moves_folder = root / "assets" / "datafiles" / "moves"
    move_export_json = {"list": []}
    for move_source in moves_folder.iterdir():
        with move_source.open("r") as f:
            data = json.load(f)
            move = move_source.stem

            move_entry = {"name": move, "desc": ""}
            if move == "Error":
                continue

            if "scaling" in data:
                if "Description" not in data:
                    print(move_source)
                desc = "{desc}\n\n**Higher Levels:** {higher_levels}".format(desc=data["Description"], higher_levels=data["scaling"].replace("Higher Levels: ", ""))
            else:
                desc = data["Description"]
            move_entry["desc"] = desc

            move_power = "/".join(data["Move Power"]) if "Move Power" in data else "None"
            if "Duration" not in data:
                print(move)
                data["Duration"] = "1 round, Concentration"
            meta_string = "**Type:** {type}\n**Move Power:** {move_power}\n**Move Time:** {move_time}\n**PP:** {pp}\n**Duration:** {duration}\n**Range:** {range}".format(
                type=data["Type"], move_power=move_power, move_time=data["Move Time"], duration=data["Duration"],
                range=data["Range"], pp=data["PP"])
            move_entry["meta"] = meta_string

            move_export_json["list"].append(move_entry)
    with open(output / "avrae_moves.json", "w") as fp:
        json.dump(move_export_json["list"], fp, indent="  ", ensure_ascii=False)


def convert_extras():
    json_extra_example = {"name": "Weak Armor", "meta": "Ability",
                          "desc": "When an attack hits this Pokémon, its speed increases by 5 feet, but its AC is temporarily reduced by 1 until the end of battle (for a maximum reduction of -5)."}
    ability_source = root / "assets" / "datafiles" / "abilities.json"
    ability_export_json = {"list": []}
    with open(ability_source, "r") as f:
        ability_data = json.load(f)

        for name, data in ability_data.items():
            entry = {"name": name, "meta": "Ability"}
            if name == "Error":
                continue

            entry["desc"] = data["Description"]

            ability_export_json["list"].append(entry)

        with open(output / "avrae_abilities.json", "w") as fp:
            json.dump(ability_export_json["list"], fp, indent="  ", ensure_ascii=False)


convert_moves()
convert_extras()
