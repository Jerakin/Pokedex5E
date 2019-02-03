import json
import re

exported = r"D:\Repo\Pokemon5E\tools\scripts\MDATA.json"
output = r"D:\Repo\Pokemon5E\assets\datafiles\moves.json"

TITLE = "MDATA"
CONVERT_TO_INT = ["PP"]

DAMAGE_LEVEL = re.compile("Dmg lvl (\d+)")
DAMAGE_DICE = re.compile("(\d+)d(\d+)(\+Move|)")
SAVING_THROW = re.compile("make a (.{3}) saving throw")
converted = {}

with open(exported, "r") as fp:
    file_data = json.load(fp)
    for move, data in file_data[TITLE].items():
        converted[move] = {}
        for attribute, value in data.items():
            if not value:
                continue
            if attribute in CONVERT_TO_INT:
                try:
                    value = int(value)
                except ValueError:
                    pass
            if attribute == "Move Power":
                value = value.split("/")
            if attribute.startswith("Dmg"):
                level = DAMAGE_LEVEL.search(attribute).group(1)
                damage = DAMAGE_DICE.search(value)
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
                saving_throw = SAVING_THROW.search(value)

                if saving_throw:
                    converted[move]["Save"] = saving_throw.group(1)
            converted[move][attribute] = value
    with open(output, "w", "utf-8") as f:
        json.dump(converted, f, indent="  ", ensure_ascii=False)
