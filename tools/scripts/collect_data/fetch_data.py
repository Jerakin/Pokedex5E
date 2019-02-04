import gspread
import json
import os
import sys
from oauth2client.service_account import ServiceAccountCredentials

output_location = os.path.join(os.path.dirname(__file__), "data")
data_sheets = ["IDATA", "MDATA", "PDATA", "TDATA"]

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
            output_data[row[0]][title] = cell_value

    # Save it as utf-8
    with open(output_file, "w", encoding="utf-8") as f:
        data = json.dumps(output_data, ensure_ascii=False)
        f.write(data)
        print("Exported {}".format(output_file))

def get_worksheet(cred_file):
    scope = ['https://spreadsheets.google.com/feeds',
             'https://www.googleapis.com/auth/drive']

    with open(cred_file, "r") as f:
        cred_data = json.load(f)
        credentials = ServiceAccountCredentials.from_json_keyfile_dict(cred_data, scope)
    gc = gspread.authorize(credentials)
    return gc.open(r"Pokémon 5e Sheet Gen I - III.xlsx")


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
        else:
            print("Error: Access file not found, please provide a valid path")
    else:
        print("Please provide the access file")
