# FLOOR 21 - The Dungeon Map

Five floors left, and they are all the same project. By floor 25 you will
have a real, playable game - a dungeon you walk through, with monsters that
fight back, loot, a locked door and a save file. You are going to write it.

Everything you need, you already know. The only new thing is *scale*: from
here on you are building a program with parts, not a program with a task.

## A world is a grid of characters

```
####################
#@...#........#....#
#....#..####..#..!.#
```

`#` rock, `.` floor, `@` you, `!` a potion, `$` gold, `k` a key, `>` the
way down. That is the entire graphics engine, and games shipped like this
for twenty years.

In code it is a `std::vector<std::string>`. Each string is one row:

```
rows_[y][x]
```

**y first.** `rows_[y]` picks the row, `[x]` picks the character in it.
Everyone gets this backwards at least once - usually by writing `rows_[x][y]`
and then staring at a dungeon that is somehow inside out.

## Out of bounds is not an error, it is a decision

`rows_[99][99]` on a 20x12 map is undefined behaviour: no crash, no warning,
just garbage or a corruption you find three hours later.

So the map never gets asked directly. Everything goes through:

```
char Dungeon::tileAt(int x, int y) const {
    if (x < 0 || y < 0 || x >= width() || y >= height()) {
        return '#';
    }
    return rows_[y][x];
}
```

Outside the map is solid rock. Now movement code, monster code and rendering
code can ask about any coordinate at all and get a sensible answer. One
guard, written once, and a whole category of bug is gone.

That habit - **make the invalid case impossible to reach rather than
remembering to avoid it** - is most of what separates code that works from
code that works today.

## The player is not on the map

The map stores terrain. Where the hero is standing is a *different* fact,
and it lives in different variables. `render` takes the player position and
draws `@` on top:

```
if (x == playerX && y == playerY) std::cout << '@';
else                              std::cout << rows_[y][x];
```

If you wrote the `@` into `rows_` instead, moving would mean erasing the old
one and remembering what used to be underneath. Try it once, some day, to
feel why nobody does it.

## Your task

`dungeon.h` and `main.cpp` are written for you. Read `dungeon.h` first - it
is the contract. Then write `dungeon.cpp`.

The constructor builds `rows_` from the map below, finds the `@`, records it
in `startX_` / `startY_`, and replaces that tile with `.`:

```
####################
#@...#........#....#
#....#..####..#..!.#
#....#..#..#..#....#
#.####..#..#..####.#
#....#..#..#.......#
#.$..#..#.##..####.#
#....#........#..#.#
#.####.########..#.#
#......#k........#.#
#.####............>#
####################
```

Then implement `width`, `height`, `tileAt`, `setTile`, `isWall`, `render`,
`startX` and `startY` - all of them out of line, with `Dungeon::`.

`isWall` is `tileAt(x, y) == '#'`. `setTile` must ignore out-of-range
coordinates rather than crash.

Running `main.cpp` should give you:

```
-- THE DUNGEON OF THE NULL POINTER --
size: 20x12
start: 1,1
```

followed by the map with `@` at 1,1, some tile queries, and the map again
with `@` standing on the gold at 2,6.

> Every `.cpp` in your workspace gets compiled and linked together, exactly
> like floor 19. You will be adding more files each floor from here.
