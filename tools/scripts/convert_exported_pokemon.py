import json
import re

exported = r"D:\Repo\Pokemon5E\tools\scripts\PDATA.json"
output = r"D:\Repo\Pokemon5E\assets\datafiles\pokemon.json"

output_meta = r"D:\Repo\Pokemon5E\assets\datafiles\pokemon_order.json"

TITLE = "PDATA"
CONVERT_TO_INT = ["CR", "AC", "Hit Dice", "HP", "WSp", "Ssp", "Fsp", "STR", "CON", "DEX", "INT", "WIS", "CHA", "Ev", "MIN LVL FD"]

STARTING_MOVES = re.compile("Starting Moves: ([A-Za-z, ]*)")
ABILITIES = re.compile("Abilities: ([A-Za-z, ]*)")
LEVEL_MOVES = re.compile("Level (\d+): ([A-Za-z ,]*)")

converted = {}
with open(exported, "r") as fp:
    file_data = json.load(fp)
    order = []
    for pokemon, data in file_data[TITLE].items():
        order.append(pokemon)
        converted[pokemon] = {"Moves":{"Level":{}}}
        for attribute, value in data.items():
            if not value:
                continue
            if attribute in CONVERT_TO_INT:
                value = float(value)

            if attribute in ["Skill", "Res", "Vul", "Imm"]:
                value = value.split(", ")

            if attribute == "Type":
                value = value.split("/")

            if attribute == "Moves":
                converted[pokemon]["Moves"]["Starting Moves"] = STARTING_MOVES.match(value).group(1).split(", ")

                lvl_moves = LEVEL_MOVES.search(value)
                if lvl_moves:
                    level = lvl_moves.group(1)
                    moves = lvl_moves.group(2).split(", ")
                    converted[pokemon]["Moves"]["Level"][level] = moves
                abilities = ABILITIES.search(value)
                if abilities:
                    converted[pokemon]["Abilities"] = abilities.group(1).split(", ")
                continue
            converted[pokemon][attribute] = value

    with open(output_meta, "w") as f:
        json.dump({"number": order}, f, indent="  ")

    with open(output, "w") as f:
        json.dump(converted, f, indent="  ")
