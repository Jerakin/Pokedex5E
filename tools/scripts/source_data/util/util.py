import json
from pathlib import Path
import sys
import logging

# Add some colors to the logging output
logging.addLevelName(logging.DEBUG, "\x1b[38;21m%s\033[1;0m" % logging.getLevelName(logging.DEBUG))
logging.addLevelName(logging.INFO, "\x1b[1;32m%s\033[1;0m" % logging.getLevelName(logging.INFO))
logging.addLevelName(logging.WARNING, "\x1b[33;21m%s\033[1;0m" % logging.getLevelName(logging.WARNING))
logging.addLevelName(logging.ERROR, "\x1b[31;21m%s\033[1;0m" % logging.getLevelName(logging.ERROR))

# Paths
ROOT = Path(__file__).parent.parent
DATA = ROOT / "data"
ASSETS = ROOT / "assets"

OUTPUT = ROOT.parent.parent.parent / "assets" / "datafiles"
POKEMON_OUTPUT = OUTPUT / "pokemon"
MOVES_OUTPUT = OUTPUT / "moves"

# Constants
ATTRIBUTES = ["STR", "CON", "DEX", "INT", "WIS", "CHA"]


def __load(path):
    with path.open(encoding="utf-8") as fp:
        json_data = json.load(fp)
    return json_data


def load_extra(name):
    p = Path(ASSETS / "extra" / name).with_suffix(".json")
    return __load(p)


# Data holders that's read in to memory for simplicity
MERGE_POKEMON_DATA = load_extra("pokemon")
MERGE_EVOLVE_DATA = load_extra("evolve")
MERGE_FILTER_DATA = load_extra("filter_data")
MERGE_MOVE_DATA = load_extra("moves")
MERGE_ABILITY_DATA = load_extra("abilities")


def merge(a, b, path=None):
    """merges b into a"""
    if path is None: path = []
    for key in b:
        if key in a:
            if isinstance(a[key], dict) and isinstance(b[key], dict):
                merge(a[key], b[key], path + [str(key)])
            elif a[key] == b[key]:
                pass  # same value
            else:  # Overwrite value
                a[key] = b[key]
                # raise Exception('Conflict at %s' % '.'.join(path + [str(key)]))
        else:
            a[key] = b[key]
    return a


def update_progress(progress):
    bar_length = 50  # Modify this to change the length of the progress bar
    status = ""
    if isinstance(progress, int):
        progress = float(progress)
    if not isinstance(progress, float):
        progress = 0
        status = "error: progress var must be float\r\n"
    if progress < 0:
        progress = 0
        status = "Halt...\r\n"
    if progress >= 1:
        progress = 1
        status = "Done...\r\n"
    block = int(round(bar_length*progress))
    text = "\rPercent: [{}] {:.1f}% {}".format("#"*block + "-"*(bar_length-block), progress*100, status)
    sys.stdout.write(text)
    sys.stdout.flush()


def ensure_int(value):
    if value:
        return int(value)
    return None


def ensure_float(value):
    if value:
        return float(value)
    return None


def ensure_string(value):
    if value and value != "None":
        return value.strip('"').strip()
    return None


def ensure_list(value, sep=','):
    if value:
        return [ensure_string(x) for x in value.split(sep)]
    return None


def clean_object(obj):
    if not obj:
        return
    for index in range(len(obj))[::-1]:
        if not obj[index] or obj[index] == "None":
            del obj[index]


def clean_dict(d):
    if type(d) is dict:
        return dict((k, clean_dict(v)) for k, v in d.items() if v is not None)
        # return {k: v for k, clean_output(v) in d.items() if v is not None}
    else:
        return d
