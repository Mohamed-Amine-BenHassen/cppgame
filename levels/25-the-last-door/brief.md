# FLOOR 25 - The Last Door   [FINAL]

One floor left. Your game can be walked through, fought in and looted. It
cannot be **won**, and it cannot be **left and come back to**. Both of those
are what turns a toy into a game, and you have already learned everything
they need.

## An ending is just a state

A game without a win condition is a screensaver with opinions. Yours has a
door at the bottom right and a key hidden behind a goblin. That is a whole
game design: a goal, an obstacle, and a reason to go the long way round.

```
if (dungeon_.tileAt(px_, py_) != '>') return;

if (pack_.has("iron key")) {
    // won
} else {
    // locked
}
```

Notice the ogre standing between you and that door. Nothing in the code says
"the ogre guards the exit" - it emerges from a position and a damage roll.
That is level design, and you just did some.

## Saving is writing your state down

A save file is every piece of mutable state, in an order the reader agrees
with. Look at what your Game actually holds:

- where the hero is, their hp, gold and step count
- the terrain, because loot has been taken off it
- each monster's remaining hp
- what is in the pack

Anything you leave out comes back wrong. Anything you write in a different
order than you read comes back scrambled. That is the whole craft of it.

`tileAt` and `setTile` are exact inverses, which is what makes the map
round-trip cleanly. Small interfaces pay you back later.

And once more, for the third and last time: after reading a number with
`>>`, clear the leftover newline before you `getline`.

## Your task

Your workspace arrives holding the reference floor 24 game, plus updated
`monster.h`, `pack.h` and `game.h`. Three small additions and one big one.

**monster.cpp** - implement `void Monster::setHp(int hp)`. A loaded game has
wounded monsters.

**pack.cpp** - implement `const std::vector<std::string>& Pack::items() const`,
returning `items_`. The save needs to walk them one by one, which `list()`
cannot do.

**game.cpp:**

`void Game::checkExit()` - called from `step()` right after `pickUp()`.

- not standing on `>` -> nothing happens
- on `>` without the key -> `the door is iron, and locked. something in here opens it.`
- on `>` with the key -> the hero wins:

```
=====================================
  YOU CLIMB THE STAIR INTO DAYLIGHT
=====================================
gold: 137
steps: 42
monsters slain: 1
```

then `running_ = false;` and `won_ = true;` - no monsters act, no map is drawn.

`void Game::save()` - write `dungeon.sav`, in exactly this order:

```
<px> <py>
<hp> <maxHp>
<gold> <steps>
<width> <height>
<height lines of raw terrain, from tileAt>
<how many monsters>
<one line per monster: its hp>
<how many items in the pack>
<one line per item>
```

then print `saved.`

`void Game::load()` - read it back in the same order and print `loaded.`,
then `draw()`. If the file is not there, print `no save file found.` and
change nothing. Empty the pack with `pack_ = Pack(6);` before refilling it,
or loading twice gives you two of everything.

`void Game::help() const` - print:

```
-- commands --
w a s d   move, or attack whatever you walk into
i         look in your pack
p         drink a potion
save      write dungeon.sav
load      read dungeon.sav
?         this list
q         give up
```

**Wire them into run().** `save`, `load`, `i` and `?` are all **free** - they
cost no turn and no monster acts. Update the header line to:

```
w a s d to move, i pack, p potion, ? help, q leave
```

`steps taken: <n>` still prints at the very end, after everything, win or
lose.

## And then you are done

When the trials pass, `workspace\25-the-last-door` holds roughly seven hundred
lines of C++ across eleven files: a dungeon, a monster hierarchy, an
inventory, a combat system, a save format and a game loop. You wrote it.

Play it properly before you check it. Find the key. Get past the ogre. Save
before you try something stupid.

Then open a new folder and build the next one - a bigger map, a shop, a
second dungeon level, monsters that chase you. Nothing in this tower is
holding you up any more.
