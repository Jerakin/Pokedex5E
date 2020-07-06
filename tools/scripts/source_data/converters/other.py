import json
import csv
try:
    import scripts.source_data.util.util as util
except ModuleNotFoundError:
    from util import util


def __convert(_input, name, key):
    json_data = {}
    with open(_input, "r", encoding="utf-8") as fp:
        reader = csv.reader(fp, delimiter=",", quotechar='"')
        next(reader)

        for row in reader:
            if row:
                json_data[row[0]] = {key: row[1].strip()}

    with open(util.OUTPUT / (name + ".json"), "w", encoding="utf-8") as f:
        json.dump(json_data, f, indent="  ", ensure_ascii=False, sort_keys=True)


def convert_idata(input_file):
    __convert(input_file, "items", "Effect")


def convert_tdata(input_file):
    __convert(input_file, "abilities", "Description")
