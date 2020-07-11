# -*- coding: utf-8 -*-
import gspread
import csv
import json
import os
import sys
from pathlib import Path

from oauth2client.service_account import ServiceAccountCredentials

try:
    import scripts.source_data.util.util as util
except ModuleNotFoundError:
    from util import util


DATA_SHEETS = ["IDATA", "MDATA", "PDATA", "TDATA"]


def save_worksheet(worksheet):
    if not util.DATA.exists():
        util.DATA.mkdir(parents=True)

    output_file = Path(util.DATA) / (worksheet.title + ".csv")

    with open(output_file, "w", encoding="utf-8") as f:
        writer = csv.writer(f, delimiter=",", quotechar='"')
        content = worksheet.get_all_values()
        for row in content:
            new_row = []
            for record in row:
                new_row.append(record)
            try:
                writer.writerow(new_row)
            except (UnicodeEncodeError, UnicodeDecodeError):
                print("Caught unicode error")


def get_worksheet(cred_file):
    scope = ['https://spreadsheets.google.com/feeds',
             'https://www.googleapis.com/auth/drive']

    with open(cred_file, "r") as f:
        cred_data = json.load(f)
        credentials = ServiceAccountCredentials.from_json_keyfile_dict(cred_data, scope)
    gc = gspread.authorize(credentials)

    return gc.open(r"DM Pokémon Builder Gen I - VI.xlsx")


def main(cred_file):
    wks = get_worksheet(cred_file)
    for worksheet in wks.worksheets():
        if worksheet.title in DATA_SHEETS:
            save_worksheet(worksheet)
    return util.DATA


if __name__ == '__main__':
    if len(sys.argv) == 2:
        credentials_file = sys.argv[1]
        if os.path.exists(credentials_file):
            main(cred_file=credentials_file)
        else:
            print("Error: Access file not found, please provide a valid path")
    else:
        print("Please provide the access file")
