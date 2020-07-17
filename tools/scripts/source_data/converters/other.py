import json
import csv
try:
    import scripts.source_data.util.util as util
except ModuleNotFoundError:
    from util import util


MERGE_DATA = {
    "abilities": util.MERGE_ABILITY_DATA
}


def __convert(_input, file_name, key):
    json_data = {}
    with open(_input, "r", encoding="utf-8") as fp:
        reader = csv.reader(fp, delimiter=",", quotechar='"')
        next(reader)

        for row in reader:
            if row:
                name = row[0]
                json_data[name] = {key: row[1].strip()}
                if file_name in MERGE_DATA and name in MERGE_DATA[file_name]:
                    util.merge(json_data[name], MERGE_DATA[file_name][name])

    with open(util.OUTPUT / (file_name + ".json"), "w", encoding="utf-8") as f:
        json.dump(json_data, f, indent="  ", ensure_ascii=False, sort_keys=True)


def convert_idata(input_file):
    __convert(input_file, "items", "Effect")


def convert_tdata(input_file):
    __convert(input_file, "abilities", "Description")
