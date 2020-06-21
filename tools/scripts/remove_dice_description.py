import re
from pathlib import Path
import json

reg_damage_dice = re.compile("(?i)(?:(\d)x|X|)(\d+|)d(\d+)\s*(\+\s*move|)(?:\+\s*(\d)|)(\+\s*level|)")

move_path = Path(r"E:\projects\repositories\Pokedex5E\assets\datafiles\moves.json")

with move_path.open(encoding="utf-8") as fp:
    move_data = json.load(fp)

for name, data in move_data.items():
    dice = reg_damage_dice.search(data["Description"])
    if dice and "Damage" in data:
        data["Description"] = data["Description"].replace(f'{dice.group(0)}', " ").replace("  ", "")

with move_path.open("w", encoding="utf-8") as fp:
    json.dump(move_data, fp, indent=2, ensure_ascii=False)
