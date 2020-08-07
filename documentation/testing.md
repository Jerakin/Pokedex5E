# Testing

## Trainer

Create a Bulbasuar at level 20. Give him the moves Tackle, Razor Leaf, and Acid Spray

These should be the numbers when changing the corresponding Trainer values

### STAB
|            | None | Pokemon STAB | Move STAB | Pokemon STAB |
|------------|------|--------------|-----------|--------------|
|            |      | Poison +1    | Poison +1 | Poison +1    |
|            |      |              |           | All Level +1 |
| Tackle     | 1    | 1            | 1         | 2            |
| Razor Leaf | 6    | 7            | 6         | 8            |
| Acid Spray | 6    | 7            | 7         | 8            |
| Struggle   | 1    | 1            | 1         | 1            |


### STAB with Always Use STAB (Poison)
|            | None | Only Always use | Move STAB | Pokemon STAB |
|------------|------|-----------------|-----------|--------------|
|            |      |                 | Poison +1 | Poison +1    |
| Tackle     | 1    | 6               | 7         |  6           |
| Razor Leaf | 6    | 6               | 7         |  6           |
| Acid Spray | 6    | 6               | 7         |  7           |
| Struggle   | 1    | 1               | 1         |  1           |


### AB
|            | None | Pokemon AB | Move AB   |
|------------|------|------------|-----------|
|            |      | Poison +1  | Poison +1 |
|            |      | Grass +2   | Grass +2  |
| Tackle     | 7    | 7          | 7         |
| Razor Leaf | 7    | 9          | 9         |
| Acid Spray | 7    | 9          | 8         |
| Struggle   | 7    | 9          | 7         |


