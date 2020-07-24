import re
import json

try:
    import scripts.source_data.util.util as util
except ModuleNotFoundError:
    from util import util

RE_DAMAGE_DICE = re.compile("(?i)((?:(\d)x|X|)(?:\d+)d(?:\d+)\s*(?:\+\s*move|)(?:\+\s*(?:\d)|)(?:\+\s*level|))")


def remove_dice(data):
    dice = RE_DAMAGE_DICE.findall(data["Description"])
    if dice and "Damage" in data:
        for die in dice:
            data["Description"] = ' '.join(data["Description"].replace(die[0], "").split())


if __name__ == '__main__':
    for move_path in util.MOVES_OUTPUT:
        with move_path.open(encoding="utf-8") as fp:
            _move_data = json.load(fp)
        remove_dice(_move_data)
        with move_path.open("w", encoding="utf-8") as fp:
            json.dump(_move_data, fp, indent=2, ensure_ascii=False)