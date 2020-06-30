import json
from pathlib import Path

CONVERTER = Path(__file__).parent
ASSETS = CONVERTER / "assets"
OUTPUT = CONVERTER.parent.parent.parent.parent.parent / "assets" / "datafiles"
POKEMON_OUTPUT = OUTPUT / "pokemon"

ATTRIBUTES = ["STR", "CON", "DEX", "INT", "WIS", "CHA"]

def __load(path):
    with path.open(encoding="utf-8") as fp:
        json_data = json.load(fp)
    return json_data


def load_extra(name):
    p = Path(ASSETS / "extra" / name).with_suffix(".json")
    return __load(p)


MERGE_POKEMON_DATA = load_extra("pokemon")


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