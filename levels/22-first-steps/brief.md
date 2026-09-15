# FLOOR 22 - First Steps

The dungeon exists. Nobody is in it yet.

This floor adds the thing that makes software a *game*: a loop that reads
what the player wants, changes the world, and shows them the result. Read,
update, draw. Every game ever written is that loop.

## The shape

```
while (std::getline(std::cin, cmd)) {
    // 1. work out what they meant
    // 2. change the world
    // 3. show them
}
```

Your `while (level < 5)` from floor 5 waited for a number to change. This one
waits for a person. When `getline` finally returns false the input has run
out - which for you now means the player closed the game.

## Where the player is

The hero is not on the map (floor 21). Their position is two ints in `main`:

```
int px = d.startX();
int py = d.startY();
```

## Try, then commit

The wrong way to move:

```
py = py - 1;
if (d.isWall(px, py)) { py = py + 1; }   // oops, put it back
```

That works until something else runs between the two lines, and then you have
a hero standing inside a wall. The right way is to look before you leap:

```
int nx = px;
int ny = py;
if (cmd == "w") { ny = py - 1; }
...
if (d.isWall(nx, ny)) {
    std::cout << "a wall blocks you\n";
} else {
    px = nx;
    py = ny;
    ...
}
```

Compute the target, test the target, *then* commit. The player is never in an
invalid state, not even for one line.

**Up is minus one.** Row 0 is the top of the map, so `w` decreases `y`. This
feels wrong for about a week and then never again.

## Your task

`dungeon.h` and `dungeon.cpp` are already in your workspace - the reference
version from floor 21, so every floor from here starts from the same ground.
You write `main.cpp`.

Start by printing:

```
-- THE DUNGEON OF THE NULL POINTER --
w a s d to move, q to leave
```

then render the map with the hero at the start position.

Then loop over lines of input:

- `w` `a` `s` `d` - try to move north, west, south, east
  - if the target is a wall: print `a wall blocks you` and nothing else
  - otherwise: move, print `you step <north|west|south|east>`, then render
- `q` - print `you climb back out.` and leave the loop
- anything else - print `you cannot do that.`

When the loop ends for any reason - `q` or the input running out - print:

```
steps taken: <n>
```

Only successful moves count as steps. Bumping a wall is not a step.

If the input runs out without a `q`, print `the dungeon goes quiet.` before
the steps line.

The start of a run with input `d`, `d`, `w`, `s`, `s`, `q`:

```
-- THE DUNGEON OF THE NULL POINTER --
w a s d to move, q to leave
####################
#@...#........#....#
...
you step east
####################
#.@..#........#....#
...
```

> Play it yourself with `.\play.ps1 run` before you check it. Walk into a few
> walls. This is the first thing you have written that is genuinely fun to
> poke at, and poking at it is how you will find the bugs.
