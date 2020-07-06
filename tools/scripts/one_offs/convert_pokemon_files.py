import json
from pathlib import Path
import copy

translate_names = {
    "Moves": "m",
    "Level": "l",
    "Starting Move": "sm",
    "TM": "tm",
    "index": "i",
    "Abilities": "a",
    "Type": "t",
    "SR": "sr",
    "AC": "ac",
    "HP": "hp",
    "Hit Dice": "hd",
    "attributes": "atr",
    "MIN LVL FD": "lvl",
    "SKill": "s",
    "Senses": "sn",
    "Hidden Ability": "ha",
    "Evolve": "e",
    "saving_throws": "st"
 }


def convert_names(json_data):
    json_copy = copy.deepcopy(json_data)
    for key, value in json_data.items():
        if key in translate_names:
            json_copy[translate_names[key]] = json_copy.pop(key)
    return json_copy


def convert_speeds(json_data):
    json_copy = copy.deepcopy(json_data)
    translate = {"WSp": "w",
                 "SSp": "s",
                 "FSp": "f",
                 "Climbing Speed": "c",
                 "Burrowing Speed": "b",
    }

    json_copy["sp"] = {}
    for speed_from, speed_to in translate.items():
        if speed_from in json_copy:
            json_copy["sp"][speed_to] = json_copy.pop(speed_from)
    return json_copy


def convert(path):
    with path.open(encoding="utf-8") as fp:
        data = json.load(fp)
    j_copy = convert_speeds(data)
    j_copy = convert_names(j_copy)

    with path.open("w", encoding="utf-8") as fp:
        json.dump(j_copy, fp, ensure_ascii=False, indent=2)


convert(Path(r"E:\projects\repositories\Pokedex5E\assets\datafiles\pokemon\Abomasnow.json"))
