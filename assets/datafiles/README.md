# To add a Fakémon

All data files provided will combine with the apps already made. If there is a KEY in the new definitions that are also in the Apps original files then the KEY from the new files will take precedence. Meaning you can overwrite Bulbasaurs values by adding him in the custom definitions.

Only one custom package can be provided.

## Warning
Please remember that _EVERYTHING_ needs to be spelled correctly, including lower and uppercase. Spelling Fakemon as "fakemon" will create an undefined error somewhere.

### Minimum needed

##### pokemon.json
This file is the main info about the Pokémon. It dictates which moves it can learn and which it have at the start, it says which TMs can be used on it as well as say all attributes. 
```
  "Fakemon": {
    "sprite": "",
    "icon": "",
    "Moves": {
      "Level": {
        "2": [
          "Vine Whip",
          "Leech Seed"
        ],
        "6": [
          "Poison Powder",
          "Sleep Powder",
          "Take Down",
          "Razor Leaf"
        ],
        "10": [
          "Sweet Scent",
          "Growth",
          "Double-Edge"
        ],
        "14": [
          "Worry Seed",
          "Synthesis"
        ],
        "18": [
          "Seed Bomb"
        ]
      },
      "Starting Moves": [
        "Tackle",
        "Growl"
      ],
      "TM": [
        1,
        6,
        9,
        10,
        11,
        16,
        17,
        20,
        21,
        22,
        27,
        32,
        36,
        42,
        44,
        45,
        48,
        49,
        53,
        75,
        86,
        87,
        88,
        90,
        96,
        100
      ]
    },
    "index": 1,
    "Abilities": [
      "Overgrow"
    ],
    "Type": [
      "Grass",
      "Poison"
    ],
    "SR": 0.5,
    "AC": 13,
    "Hit Dice": 6,
    "HP": 17,
    "WSp": 30,
    "attributes": {
      "STR": 13,
      "DEX": 12,
      "CON": 12,
      "INT": 6,
      "WIS": 10,
      "CHA": 10
    },
    "MIN LVL FD": 1,
    "Evolve": "Fakemon-Z",
    "saving_throws": [
      "STR"
    ],
    "Skill": [
      "Athletics",
      "Nature"
    ],
    "Res": [
      "Electric",
      "Fairy",
      "Fighting",
      "Grass",
      "Water"
    ],
    "Vul": [
      "Fire",
      "Flying",
      "Ice",
      "Psychic"
    ],
    "Hidden Ability": "Chlorophyll"
  }
```
##### pokemon_order.json
This file dictates which order the Pokémon sort in for the PC.
This file needs _all_ of the Pokémon's in it.
```
  "number": [
    "Bulbasaur",
    "Ivysaur",
    "Venusaur",
    ...
    "Arceus (Electric)",
    "Arceus (Psychic)",
    "Arceus (Ice)",
    "Arceus (Dragon)",
    "Arceus (Dark)",
    "Arceus (Fairy)"
    "Fakemon",
    "Fakemon-Z"
  ]
```

### Evolutions

All evolutions will of course need to be in the `pokemon.json` file.

##### evolve.json
Dictates if the Pokémon have an evolution and if it does into what, when it can evolve and how many ASI points it gets.

```
  "Fakemon": {
    "into": [
      "Fakemon-Z"
    ],
    "points": 11,
    "level": 11
  }
```

### Pokedex

##### pokedex_extra.json

This file adds the Pokémon text to the Pokedex dialog
```
  "Fakemon":{
    "flavor": "Fakemon is often seen near watering holes praying on other Fakemons",
    "height": 15,
    "weight": 12,
    "genus": "Fake Pokémon"
  }
```
 
 
##### pokemon_order.json

This file dictates which order the Pokémon will show up in the dex, it is essentially the "index numbers" for the pokemons.
This file needs _all_ of the Pokémon's in it.

```
  "unique" = [
    "Bulbasaur",
    "Ivysaur",
    "Venusaur",
    ...
    "Darkrai",
    "Shaymin Land",
    "Arceus (Normal)",
    "Fakemon",
    "Fakemon-Z"
  ]
```
