import re
import csv
import json

from collect_data.data.converter import util


export_folder = ""

POKEMON = "Pokémon"

DEFAULT_HEADER = ("Index Number", "Evo Stages with Eviolite", "Evo Stages w/o Eviolite", POKEMON, "Type", "SR", "AC",
                  "Hit Dice", "HP", "", "", "WSp", "Ssp", "Fsp", "Senses", "STR", "DEX", "CON", "INT", "WIS", "CHA",
                  "MIN LVL FD", "Ev", "Evolve", "Evo Stages", "ST1", "ST2", "ST3", "Skill", "Res", "Vul", "Imm",
                  "Ability1", "Ability2", "HiddenAbility", "Moves", "Evolution for sheet", "Evolve Bonus",
                  "Climbing Speed", "Burrowing Speed", "Description 17")


def _int(value):
    if value:
        return int(value)
    return None


def _float(value):
    if value:
        return float(value)
    return None


def _string(value):
    if value and value != "None":
        return value.strip('"').strip()
    return None


def _list(value, sep=','):
    if value:
        return [_string(x) for x in value.split(sep)]
    return None


def _clean(obj):
    if not obj:
        return
    for index in range(len(obj))[::-1]:
        if not obj[index] or obj[index] == "None":
            del obj[index]


def clean_file_name(value):
    return value.replace(" ♀", "-f").replace(" ♂", "-m").replace("é", "e").replace("\n", " ")


def fix_species_name(value):
    return value.replace(" - Small", "").replace("\n", " ").replace("Zygarde Complete Form", "Zygarde Complete Forme")


def _clean_output(d):
    if type(d) is dict:
        return dict((k, _clean_output(v)) for k, v in d.items() if v is not None)
        # return {k: v for k, clean_output(v) in d.items() if v is not None}
    else:
        return d


class Pokemon:
    RE_STARTING_MOVES = re.compile("Starting Moves: ([A-Za-z ,-12']*)")
    RE_TM_MOVES = re.compile("TM: (.*)")
    RE_LEVEL_MOVES = re.compile("Level (\d+): ([A-Za-z ,-]*)")

    def __init__(self, header):
        self.header = header
        self.name = None
        self.output_data = {}
        self.valid = True

    def setup_basic_stats(self, csv_row):
        self.output_data["index"] = _int(csv_row[self.header.index("Index Number")])
        self.output_data["SR"] = _float(csv_row[self.header.index("SR")])
        self.output_data["Hit Dice"] = _int(csv_row[self.header.index("Hit Dice")])
        self.output_data["MIN LVL FD"] = _int(csv_row[self.header.index("MIN LVL FD")])
        self.output_data["HP"] = _int(csv_row[self.header.index("HP")])
        self.output_data["AC"] = _int(csv_row[self.header.index("AC")])
        self.output_data["Evolve"] = _string(csv_row[self.header.index("Evolve")])

    def setup_speed(self, csv_row):
        self.output_data["WSp"] = _int(csv_row[self.header.index("WSp")])
        self.output_data["Ssp"] = _int(csv_row[self.header.index("Ssp")])
        self.output_data["Fsp"] = _int(csv_row[self.header.index("Fsp")])
        self.output_data["Climbing Speed"] = _int(csv_row[self.header.index("Climbing Speed")])
        self.output_data["Burrowing Speed"] = _string(csv_row[self.header.index("Burrowing Speed")])

    def setup_attributes(self, csv_row):
        self.output_data["attributes"] = {}
        self.output_data["attributes"]["STR"] = _int(csv_row[self.header.index("STR")])
        self.output_data["attributes"]["DEX"] = _int(csv_row[self.header.index("DEX")])
        self.output_data["attributes"]["CON"] = _int(csv_row[self.header.index("CON")])
        self.output_data["attributes"]["INT"] = _int(csv_row[self.header.index("INT")])
        self.output_data["attributes"]["WIS"] = _int(csv_row[self.header.index("WIS")])
        self.output_data["attributes"]["CHA"] = _int(csv_row[self.header.index("CHA")])

    def setup_abilities(self, csv_row):
        self.output_data["Abilities"] = []
        self.output_data["Abilities"].append(csv_row[self.header.index("Ability1")])
        self.output_data["Abilities"].append(csv_row[self.header.index("Ability2")])
        self.output_data["Hidden Ability"] = _string(csv_row[self.header.index("HiddenAbility")])

        _clean(self.output_data["Abilities"])

    def setup_senses(self, csv_row):
        self.output_data["Senses"] = _list(csv_row[self.header.index("Senses")])

    def setup_type(self, csv_row):
        self.output_data["Type"] = _list(csv_row[self.header.index("Type")], "/")

    def setup_skill(self, csv_row):
        self.output_data["Skill"] = _list(csv_row[self.header.index("Skill")])
        _clean(self.output_data["Skill"])
        if not self.output_data["Skill"]:
            del self.output_data["Skill"]

    def setup_saving_throws(self, csv_row):
        self.output_data["saving_throws"] = []
        first_saving_throw = csv_row[self.header.index("ST1")]
        if "All" in first_saving_throw:
            self.output_data["saving_throws"] = util.ATTRIBUTES
        else:
            self.output_data["saving_throws"].append(first_saving_throw)
            self.output_data["saving_throws"].append(csv_row[self.header.index("ST2")])
            self.output_data["saving_throws"].append(csv_row[self.header.index("ST3")])
        _clean(self.output_data["saving_throws"])
        if not self.output_data["saving_throws"]:
            del self.output_data["saving_throws"]

    def setup_moves(self, csv_row):
        self.output_data["Moves"] = {}
        self.output_data["Moves"]["Level"] = {}
        self.output_data["Moves"]["Starting Moves"] = []
        self.output_data["Moves"]["TM"] = []
        move_text = csv_row[self.header.index("Moves")]
        starting_moves = self.RE_STARTING_MOVES.match(move_text)
        if starting_moves:
            self.output_data["Moves"]["Starting Moves"] = _list(starting_moves.group(1))

        lvl_moves = self.RE_LEVEL_MOVES.findall(move_text)
        if lvl_moves:
            for level, moves in lvl_moves:
                self.output_data["Moves"]["Level"][level] = [x.replace(",", "") for x in moves.split(", ") if
                                                                x.replace(",", "")]
        tm_moves = self.RE_TM_MOVES.search(move_text)
        if tm_moves:
            if "EVERY TM" in move_text:
                self.output_data["Moves"]["TM"] = [int(x) for x in range(1, 101)]
            else:
                self.output_data["Moves"]["TM"] = [int(x) for x in re.findall(r"[0-9]+", tm_moves.group(1))]

        if not self.output_data["Moves"]["TM"]:
            del self.output_data["Moves"]["TM"]

    def setup(self, csv_row):
        self.name = fix_species_name(csv_row[self.header.index(POKEMON)])
        if "Average" in self.name or "Large" in self.name or "Supersize" in self.name:
            # This is to filter out Pokemon that have size variants
            self.valid = False
            return

        self.setup_abilities(csv_row)
        self.setup_attributes(csv_row)
        self.setup_basic_stats(csv_row)
        self.setup_moves(csv_row)
        self.setup_saving_throws(csv_row)
        self.setup_senses(csv_row)
        self.setup_skill(csv_row)
        self.setup_speed(csv_row)
        self.setup_type(csv_row)

        if self.name in util.MERGE_POKEMON_DATA:
            util.merge(self.output_data, util.MERGE_POKEMON_DATA[self.name])

    def save(self):
        name = clean_file_name(self.name)
        with (util.POKEMON_OUTPUT / (name + ".json")).open("w", encoding="utf-8") as fp:
            json.dump(_clean_output(self.output_data), fp, ensure_ascii=False, indent="  ", sort_keys=True)


class Evolve:
    RE_POINTS = re.compile("gains (\d{1,2})")
    RE_LEVEL = re.compile("level (\d{1,2})")
    RE_MOVE = re.compile("'(.*)'")
    RE_HOLDING = re.compile("while holding a (.*)\.")

    def __init__(self, header, pokemon_list):
        self.header = header
        self.pokemon_list = pokemon_list.list
        self.output_data = {}

    def add(self, csv_row):
        species = fix_species_name(csv_row[self.header.index(POKEMON)])
        self.output_data[species] = {}
        self.output_data[species]["into"] = []
        self.output_data[species]["current_stage"] = _int(csv_row[self.header.index("Evo Stages with Eviolite")])
        self.output_data[species]["total_stages"] = _int(csv_row[self.header.index("Evo Stages w/o Eviolite")])
        evolve_text = csv_row[self.header.index("Evolution for sheet")]

        # Iterate all Pokemon names and see if they are in the description
        for poke in self.pokemon_list:
            if not poke == species and " {} ".format(poke) in evolve_text:
                self.output_data[species]["into"].append(poke)

        match = self.RE_POINTS.search(evolve_text)
        if match:
            self.output_data[species]["points"] = int(match.group(1))

        match = self.RE_LEVEL.search(evolve_text)
        if match:
            self.output_data[species]["level"] = int(match.group(1))
        else:
            self.output_data[species]["level"] = 0
            match = self.RE_MOVE.search(evolve_text)
            if match:
                self.output_data[species]["move"] = match.group(1)
            else:
                match = self.RE_HOLDING.search(evolve_text)
                if match:
                    self.output_data[species]["holding"] = match.group(1)

        if not self.output_data[species]["level"]:
            del self.output_data[species]["level"]
        if not self.output_data[species]["into"]:
            del self.output_data[species]["into"]

        if self.output_data[species]["current_stage"] == 1 and self.output_data[species]["total_stages"] == 1:
            del self.output_data[species]

    def save(self):
        with (util.OUTPUT / "evolve.json").open("w", encoding="utf-8") as fp:
            json.dump(self.output_data, fp, ensure_ascii=False, indent="  ")


class PokemonList:
    """
    Holder for list of Pokemon names
    """
    def __init__(self, header):
        self.header = header
        self.list = []
        self._index = 0

    def append(self, csv_row):
        self.list.append(csv_row[self.header.index(POKEMON)])


class IndexOrder:
    def __init__(self, header):
        self.header = header
        self.output_data = {}

    def add(self, csv_row):
        value = _int(csv_row[self.header.index("Index Number")])
        species = fix_species_name(csv_row[self.header.index(POKEMON)])

        if value not in self.output_data:
            self.output_data[value] = []
        self.output_data[value].append(species)

    def save(self):
        with (util.OUTPUT / "index_order.json").open("w", encoding="utf-8") as fp:
            json.dump(self.output_data, fp, ensure_ascii=False, indent="  ")


class FilterData:
    def __init__(self, header):
        self.header = header
        self.output_data = {}

    def add(self, csv_row):
        species = fix_species_name(csv_row[self.header.index(POKEMON)])
        if species not in self.output_data:
            self.output_data[species] = {}
        self.output_data[species]["index"] = _int(csv_row[self.header.index("Index Number")])

        self.output_data[species]["Type"] = _list(csv_row[self.header.index("Type")], "/")
        self.output_data[species]["SR"] = _float(csv_row[self.header.index("SR")])
        self.output_data[species]["MIN LVL FD"] = _int(csv_row[self.header.index("MIN LVL FD")])

    def save(self):
        with (util.OUTPUT / "filter_data.json").open("w", encoding="utf-8") as fp:
            json.dump(self.output_data, fp, ensure_ascii=False, indent="  ")


class ConverterPokemon:
    def __init__(self, input_csv, header=DEFAULT_HEADER):

        with open(input_csv, "r", encoding="utf-8") as fp:
            # We need to first create a list of all Pokemon for later use
            reader = csv.reader(fp, delimiter=",", quotechar='"')

            pokemon_list = PokemonList(header)
            total = 0
            for row in reader:
                total += 1
                pokemon_list.append(row)

            # Rewind the csv file and create all the json files
            fp.seek(0)
            reader = csv.reader(fp, delimiter=",", quotechar='"')
            next(reader)

            evolve = Evolve(header, pokemon_list)
            filter_data = FilterData(header)
            index_order = IndexOrder(header)

            for index, row in enumerate(reader, 1):
                util.update_progress(index/total)

                # Each row is one Pokemon
                poke = Pokemon(header)
                poke.setup(row)
                if poke.valid:
                    poke.save()

                    evolve.add(row)
                    filter_data.add(row)
                    index_order.add(row)
            evolve.save()
            filter_data.save()
            index_order.save()


if __name__ == '__main__':
    ConverterPokemon(util.CONVERTER / "PDATA.csv")
