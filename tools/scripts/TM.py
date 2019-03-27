source = """
01 - Work Up ₽8,000 36 - Sludge Bomb ₽7,200 71 - Stone Edge ₽8,000
02 - Dragon Claw ₽6,000 37 - Sandstorm ₽8,400 72 - Volt Switch ₽5,600
03 - Psyshock ₽6,000 38 - Fire Blast ₽8,400 73 - Thunder Wave ₽5,000
04 - Calm Mind ₽5,500 39 - Rock Tomb ₽5,200 74 - Gyro Ball ₽5,500
05 - Roar ₽4,000 40 - Aerial Ace ₽5,200 75 - Swords Dance ₽8,000
06 - Toxic ₽8,000 41 - Torment ₽6,000 76 - Fly ₽7,200
07 - Hail ₽8,000 42 - Facade ₽5,600 77 - Psych Up ₽4,500
08 - Bulk Up ₽6,000 43 - Flame Charge ₽4,400 78 - Bulldoze ₽5,200
09 - Venoshock ₽5,200 44 - Rest ₽6,000 79 - Frost Breath ₽5,200
10 - Hidden Power ₽5,200 45 - Attract ₽4,000 80 - Rock Slide ₽5,600
11 - Sunny Day ₽4,400 46 - Thief ₽5,200 81 - X-Scissor ₽6,000
12 - Taunt ₽4,400 47 - Low Sweep ₽5,200 82 - Dragon Tail ₽5,200
13 - Ice Beam ₽7,200 48 - Round ₽5,200 83 - Infestation ₽2,800
14 - Blizzard ₽8,400 49 - Echoed Voice ₽4,000 84 - Poison Jab ₽6,000
15 - Hyper Beam ₽10,800 50 - Overheat ₽10,000 85 - Dream Eater ₽8,000
16 - Light Screen ₽4,400 51 - Steel Wing ₽5,600 86 - Grass Knot ₽6,500
17 - Protect ₽8,000 52 - Focus Blast ₽8,800 87 - Swagger ₽0,500
18 - Rain Dance ₽4,400 53 - Energy Ball ₽7,200 88 - Sleep Talk ₽4,500
19 - Roost ₽5,600 54 - False Swipe ₽4,000 89 - U-turn ₽5,600
20 - Safeguard ₽6,000 55 - Scald ₽6,000 90 - Substitute ₽7,500
21 - Frustration ₽3,600 56 - Fling ₽4,500 91 - Flash Cannon ₽6,000
22 - Solar Beam ₽8,800 57 - Charge Beam ₽4,400 92 - Trick Room ₽5,000
23 - Smack Down ₽4,400 58 - Sky Drop ₽5,200 93 - Wild Charge ₽7,200
24 - Thunderbolt ₽7,200 59 - Brutal Swing ₽5,200 94 - Surf ₽7,200
25 - Thunder ₽8,400 60 - Quash ₽5,600 95 - Snarl ₽4,400
26 - Earthquake ₽8,000 61 - Will-O-Wisp ₽6,000 96 - Nature Power ₽5,000
27 - Return ₽5,200 62 - Acrobatics ₽4,400 97 - Dark Pulse ₽6,000
28 - Leech Life ₽6,000 63 - Embargo ₽5,000 98 - Waterfall ₽6,000
29 - Psychic ₽7,200 64 - Explosion ₽14,000 99 - Dazzling Gleam ₽6,000
30 - Shadow Ball ₽6,000 65 - Shadow Claw ₽5,600 100 - Confide ₽4,400
31 - Brick Break ₽5,600 66 - Payback ₽4,400
32 - Double Team ₽7,000 67 - Smart Strike ₽5,600
33 - Reflect ₽8,000 68 - Giga Impact ₽10,800
34 - Sludge Wave ₽7,200 69 - Rock Polish ₽8,000
35 - Flamethrower ₽7,200 70 - Aurora Veil ₽2,500
"""

import re
import json
output = {}
regex = re.compile("([0-9]*) - (.*?)₽")

for num, move in regex.findall(source):
    output[int(num)] = move.strip()


print(json.dumps(output, sort_keys=True))