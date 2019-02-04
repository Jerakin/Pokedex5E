# How to get all that data?

## Install dependencies
`pip install -r requirements.txt`

## Setup gspread
https://gspread.readthedocs.io/en/latest/oauth2.html

## Remember to share the document with your gserviceaccount

## Edits in google sheet data
Because we are exporting the data to json you need to change the
`S, D, C, I, W, C` in the PDATA to `STR, DEX, CON, INT, WIS, CHA`

# Converting it
### Fetch data

Get and save gsheet to json with `python "/scripts/collect_data/fetch_data.py" "/path/to/my/access_file.json"`

### Convert it
Convert to the format the app wants with `python "/scripts/collect_data/convert_to_game_data.py"