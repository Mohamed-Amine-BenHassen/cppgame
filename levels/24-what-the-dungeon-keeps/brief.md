# FLOOR 24 - What the Dungeon Keeps

Walking and stabbing. Time for the third verb: **taking**.

This floor is mostly about reuse. The `Pack` you wrote on floor 15 - capacity,
add, drop, has, list - is exactly the pack this game needs. Go and get it.
That is not cheating, that is what writing a class was *for*.

## The world is allowed to change

Until now the dungeon has been read-only. Now the hero picks up a coin and
the coin has to stop being there:

```
dungeon_.setTile(px_, py_, '.');
```

That one line is the difference between an item and an infinite item. You
wrote `setTile` on floor 21 and have not used it once. This is why it exists.

Pickups happen **after** the move commits, when `px_` and `py_` are already
the new square. Look at what you are standing on, react, then erase it.

## Turns are a currency

Not every command costs a turn, and deciding which do is game design, not
programming:

- checking your inventory: free. Nobody gets hit for looking in a bag.
- drinking a potion: **a turn**. Monsters get to act. That is the whole
  tension - heal now and take a hit, or run and hope.
- trying to drink a potion you do not have: free. You did nothing.

In code that is just where you put `continue`. A tiny decision that changes
how the game feels to play.

## Your task

Your workspace arrives holding the reference floor 23 game, so a wobble back
there cannot sink this floor.

`pack.h` is given. Write `pack.cpp` - the floor 15 methods, out of line, with
`Pack::` on the front. Then extend `game.cpp`.

**The Game gains** `int gold_ = 0;` and `Pack pack_{6};` (both already
declared in the new `game.h`).

**The status line** grows a field:

```
hp 30/30   gold 0   steps 0   monsters alive 3
```

**After a successful move**, look at the tile you landed on:

- `$` -> `gold_ += roll(20) + 10;` then `you scoop up <n> gold` and clear the tile
- `!` -> try `pack_.add("potion")`.
  - it fitted -> `you pocket a potion.` and clear the tile
  - it did not -> `your pack is full.` and **leave the potion where it is**
- `k` -> `pack_.add("iron key")`, `you pocket the iron key.`, clear the tile
- anything else -> nothing

Do this before the monsters act.

**Two new commands:**

`i` - free, no turn:

```
-- pack (1/6) --
potion
gold: 137
```

(the second line is `pack_.list()`)

`p` - drink a potion:

- no potion -> `you have no potions.`, free, no turn
- otherwise -> drop one, heal `roll(8) + 8` capped at `maxHp_`, print
  `you drink a potion (hp 30/30)`, and this **is** a turn: monsters act,
  then draw.

The second header line now advertises them:

```
w a s d to move, i for your pack, p to drink, q to leave
```

Everything else from floor 23 stays exactly as it was.

> With gold on the map and a pack that fills up, this is now a game with
> decisions in it. Go and play it properly - walk to the gold at the bottom
> left, then across to the potion in the top right, and see whether the
> ogre lets you reach the key.
