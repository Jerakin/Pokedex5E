#Data Generation
The app is based on the data in [DM Pokémon Builder Gen I - VI.xlsx](https://docs.google.com/spreadsheets/d/10kCrBWr2nlPcvnriN40-4mQpsg4uUCVbDHFJXEfdfYo/edit)
by Joe. There is a script ([`fetch_data.py`](https://github.com/Jerakin/Pokedex5E/blob/master/tools/scripts/collect_data/fetch_data.py))
that downloads the csv and then does a naive conversion to json. The data is downloaded with a service account.

After the source data have been downloaded it is converted to "game data" with [`convert_to_game_data.py`](https://github.com/Jerakin/Pokedex5E/blob/master/tools/scripts/collect_data/convert_to_game_data.py)
unfortunately the script is a mess, it is one of the "it's a quick thing" that turned into "I need to patch this thing"
and now it is "oh lord why didn't I do this properly". It should be majorly refactored and rewritten from scratch.
After the script have been run there will inevitably be some data that _shouldn't_ have been changed, this data needs to
be looked over manually and be reset.

The whole workflow is then

1. Make sure that the service account have access to latest data*
2. Run `fetch_data.py` with `python fetch_data.py path_to_token.txt`**
3. Run `convert_to_game_data.py`
4. Revert lines in git that shouldn't have been changed
5. Commit the updated data

#### Idea for improvement
Rewrite the `convert_to_game_data.py`, preferably it should behave something like the [p5e-foundryVTT](https://github.com/Jerakin/p5e-foundryVTT)
project where it converts the data as best it can and then there is a separate `.json` file that have extra changes
in it that is filled out manually, at the end the script will use that `.json` to overwrite the found issues.
  
The reason to do to it this way is that the app is get a lot more frequent updates than the source data, the source data
also tends to have a lot of issues in it that sometimes doesn't get fixed.  

Downloading the data should also preferably not be relaying on a service account _or_ there should be an alternative way
to download the data.

___

*The idea with the service account was to have Joe add it to the original sheets so I could then download it
without having to download the csv manually. But I never got around asking him to do it.
  
**To do this one needs access to the service accounts, so only Jerakin can do it currently.
