import gspread
import json
import os
import sys
from oauth2client.service_account import ServiceAccountCredentials
from pathlib import Path

output_location = os.path.join(os.path.dirname(__file__), "data")
data_sheets = ["LOGIC"]


def convert_to_json(worksheet):
    output_file = os.path.join(output_location, worksheet.title + ".json")
    all_values = worksheet.get_all_values()
    header_row = all_values[:1][0]
    output_data = {}

    for row in all_values[1:]:
        output_data[row[0]] = {}
        for i, cell_value in enumerate(row):
            if i == 0: # Skipping first row
                continue
            title = header_row[i]
            output_data[row[0]][title] = cell_value.replace("Day", "").replace("Night", "").strip()

    # Save it as utf-8
    with open(output_file, "w", encoding="utf-8") as f:
        data = json.dumps(output_data, ensure_ascii=False)
        f.write(data)
        print("Exported {}".format(output_file))


def convert_to_game_data():
    output_file = Path(__file__).parent.parent.parent.parent / "assets" / "datafiles" / "habitat.json"
    input_file = os.path.join(output_location, "LOGIC.json")

    output_json = {}
    with open(input_file, "r", encoding="utf-8") as f:
        data = json.load(f)
        for species, habitats in data.items():
            for habitat, found in habitats.items():
                habitat_name = habitat.replace("Day", "").replace("Night", "").strip()
                if not habitat_name:
                    continue
                if habitat_name not in output_json:
                    output_json[habitat_name] = []
                if found == "1" and species not in output_json[habitat_name]:
                    output_json[habitat_name].append(species)

    with open(output_file, "w", encoding="utf-8") as fp:
        json.dump(output_json, fp, ensure_ascii=False)


def get_worksheet(cred_file):
    scope = ['https://spreadsheets.google.com/feeds',
             'https://www.googleapis.com/auth/drive']

    with open(cred_file, "r") as f:
        cred_data = json.load(f)
        credentials = ServiceAccountCredentials.from_json_keyfile_dict(cred_data, scope)
    gc = gspread.authorize(credentials)
    return gc.open(r"Random Pokémon Generator.xlsx")


def main(cred_file):
    wks = get_worksheet(cred_file)
    for worksheet in wks.worksheets():
        if worksheet.title in data_sheets:
            convert_to_json(worksheet)

if __name__ == '__main__':
    if len(sys.argv) == 2:
        credentials_file = sys.argv[1]
        if os.path.exists(credentials_file):
            main(cred_file=credentials_file)
            convert_to_game_data()
        else:
            print("Error: Access file not found, please provide a valid path")
    else:
        convert_to_game_data()
        print("Please provide the access file")
