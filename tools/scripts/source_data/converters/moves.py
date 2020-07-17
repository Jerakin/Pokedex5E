import re
import csv
import json

try:
    import scripts.source_data.util.util as util
    import scripts.source_data.util.remove_dice_in_description as remove_dice_in_description
except ModuleNotFoundError:
    from util import util
    from util import remove_dice_in_description

POKEMON = "Pokémon"
DEFAULT_HEADER = ("Name", "Type", "Move Power", "Move Time", "PP", "Duration", "Range", "Description",
                  "Dmg lvl 1", "Dmg lvl 5", "Dmg lvl 10", "Dmg lvl 17")


error_move = {
    "Type": "Normal",
    "Move Power": [],
    "Move Time": "1 action",
    "PP": 99,
    "Duration": "Instantaneous",
    "Range": "Melee",
    "Description": "This is an error, the app couldn't find your move report which move you tried to add",
    "Damage": {
      "1": {
        "amount": 1,
        "dice_max": 6,
        "move": True
      },
      "5": {
        "amount": 1,
        "dice_max": 6,
        "move": True
      },
      "10": {
        "amount": 1,
        "dice_max": 6,
        "move": True
      },
      "17": {
        "amount": 1,
        "dice_max": 6,
        "move": True
      }
    },
    "atk": True,
}


class Move:
    RE_DAMAGE_DICE = re.compile("(?i)(?:(\d)x|X|)(\d+|)d(\d+)\s*(\+\s*move|)(?:\+\s*(\d)|)(\+\s*level|)")
    RE_IS_HEALING = re.compile(r"((?:re|\b)gain.\b.*hit points)")
    RE_IS_ATTACK = re.compile("(?:melee|ranged) attack")
    RE_REQUIRE_SAVE = re.compile("(?:(?:make|with|succeed on) a (.{3}) sav)")

    def __init__(self, header):
        self.header = header
        self.name = None
        self.healing_move = False
        self.output_data = {}

    def setup_damage(self, csv_row):
        for key, level in {"Dmg lvl 1": 1, "Dmg lvl 5": 5, "Dmg lvl 10": 10, "Dmg lvl 17": 17, }.items():
            text = csv_row[self.header.index(key)]

            damage = self.RE_DAMAGE_DICE.search(text)
            if damage:
                amount = damage.group(2)
                amount = 0 if amount == "" else amount
                dice_max = damage.group(3)
                add_move = True if damage.group(4) else False
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
                if "Damage" not in self.output_data:
                    self.output_data["Damage"] = {}
                self.output_data["Damage"][str(level)] = dice

    def setup_extra(self, csv_row):
        text = csv_row[self.header.index("Description")]
        saving_throw = self.RE_REQUIRE_SAVE.search(text)
        is_healing = self.RE_IS_HEALING.search(text)
        is_damage = self.RE_IS_ATTACK.search(text)

        if saving_throw:
            self.output_data["Save"] = saving_throw.group(1)

        if is_healing:
            self.output_data["atk"] = False
        elif is_damage:
            self.output_data["atk"] = True

    def setup(self, csv_row):
        self.name = csv_row[self.header.index("Name")]
        self.output_data["Type"] = util.ensure_string(csv_row[self.header.index("Type")])
        self.output_data["Move Power"] = util.ensure_list(csv_row[self.header.index("Move Power")], "/")
        self.output_data["Move Time"] = util.ensure_string(csv_row[self.header.index("Move Time")])

        pp = csv_row[self.header.index("PP")]
        if pp == "Unlimited":
            self.output_data["PP"] = pp
        else:
            self.output_data["PP"] = util.ensure_int(pp)
        self.output_data["Duration"] = util.ensure_string(csv_row[self.header.index("Duration")])
        self.output_data["Range"] = util.ensure_string(csv_row[self.header.index("Range")])
        self.output_data["Description"] = util.ensure_string(csv_row[self.header.index("Description")])
        self.setup_extra(csv_row)
        self.setup_damage(csv_row)
        if self.name in util.MERGE_MOVE_DATA:
            util.merge(self.output_data, util.MERGE_MOVE_DATA[self.name])

        util.clean_object(self.output_data["Move Power"])
        if not self.output_data["Move Power"]:
            del self.output_data["Move Power"]

        remove_dice_in_description.remove_dice(self.output_data)

    def search_data(self):
        return {}

    def save(self):
        if not util.MOVES_OUTPUT.exists():
            util.MOVES_OUTPUT.mkdir()
        with (util.MOVES_OUTPUT / (self.name +".json")).open("w", encoding="utf-8") as fp:
            json.dump(util.clean_dict(self.output_data), fp, ensure_ascii=False, indent="  ", sort_keys=True)


def convert_mdata(input_csv, header=DEFAULT_HEADER):
    move_list = {}
    # Export the error move
    with open(util.MOVES_OUTPUT / "Error.json", "w", encoding="utf-8") as fp:
        json.dump(error_move, fp, ensure_ascii=False, indent="  ", sort_keys=False)

    # convert and export all moves from the CSV
    with open(input_csv, "r", encoding="utf-8") as fp:
        reader = csv.reader(fp, delimiter=",", quotechar='"')

        total = 0
        for _ in reader:
            total += 1

        # Rewind the csv file and create all the json files
        fp.seek(0)
        reader = csv.reader(fp, delimiter=",", quotechar='"')
        next(reader)

        for index, row in enumerate(reader, 1):
            if not row:
                continue
            util.update_progress(index / total)

            # Each row is one Pokemon
            move = Move(header)
            move.setup(row)
            move.save()
            move_list[move.name] = move.search_data()

    move_list["Error"] = {}
    with open(util.OUTPUT / "move_index.json", "w", encoding="utf-8") as fp:
        json.dump(move_list, fp, ensure_ascii=False, indent="  ", sort_keys=False)


if __name__ == '__main__':
    convert_mdata(util.DATA / "MDATA.csv")
