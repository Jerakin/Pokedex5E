from pathlib import Path
import sys
from gspread.exceptions import SpreadsheetNotFound

try:
    import scripts.source_data.converters.other as other
    import scripts.source_data.converters.moves as moves
    import scripts.source_data.converters.pokemon as pokemon
    import scripts.source_data.util.fetch_data as fetch
    import scripts.source_data.util.util as util
except ModuleNotFoundError:
    import converters.other as other
    import converters.moves as moves
    import converters.pokemon as pokemon
    import util.fetch_data as fetch

data_sheets = {
    "IDATA.csv": other.convert_idata,    # Items
    "MDATA.csv": moves.convert_mdata,    # Moves
    "PDATA.csv": pokemon.convert_pdata,  # Pokemon
    "TDATA.csv": other.convert_tdata     # Abilities
}


def convert_all(folder):
    for file_path in Path(folder).iterdir():
        if file_path.name in data_sheets:
            data_sheets[file_path.name](file_path)
            print(f"Converted {file_path.name}")


if __name__ == '__main__':
    if len(sys.argv) == 2:
        argument = Path(sys.argv[1])
        if argument.exists():
            if argument.is_file() and argument.suffix == ".json":
                try:
                    _folder = fetch.main(cred_file=argument)
                except SpreadsheetNotFound:
                    print("SpreadsheetNotFound: Could not find the spreadsheet on the service account")
                    sys.exit(1)
                convert_all(_folder)

            elif argument.is_dir():
                convert_all(argument)
            else:
                print("Error: Access file or folder not found, please provide a valid path")
    else:
        if (Path(__file__).parent / "data").exists:
            convert_all(Path(__file__).parent / "data")
        else:
            print("Please provide either a access file or a folder with the Download DATA sheets in")
