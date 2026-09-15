# FLOOR 23 - Things That Fight Back

Your `main` is about to get too big. That is not a style complaint - it is a
structural one. It holds the map, the player position, the step count and the
loop, and every new feature adds another loose variable that some other part
of the code has to be trusted not to break.

Floor 14 already gave you the answer: put the data and the rules in the same
box.

## The Game class

```
class Game {
public:
    Game();
    void run();

private:
    void draw() const;
    void step(int dx, int dy);
    void monstersAct();
    Monster* monsterAt(int x, int y);

    Dungeon dungeon_;
    std::vector<std::unique_ptr<Monster>> monsters_;
    int px_, py_, hp_, maxHp_, steps_;
    bool running_;
};
```

Now `main.cpp` is four lines, and every part of the game can see the state it
needs without any of it being global. A Game **has a** Dungeon and **has**
Monsters - that is **composition**, and it is the relationship you will reach
for far more often than inheritance.

## Owning versus borrowing

The game owns the monsters:

```
std::vector<std::unique_ptr<Monster>> monsters_;
```

But `monsterAt` only wants to *point at* one:

```
Monster* Game::monsterAt(int x, int y) {
    for (auto& m : monsters_) {
        if (m->isAlive() && m->x() == x && m->y() == y) {
            return m.get();
        }
    }
    return nullptr;
}
```

`m.get()` hands out the raw address **without** giving away ownership. The
caller may look and poke; the vector still owns it and will still clean it up.
That split - one owner, many borrowers - is how modern C++ is written.

`nullptr` is the answer to "there is nothing here". Check it before you use
it, every time:

```
Monster* target = monsterAt(nx, ny);
if (target != nullptr) { ... }
```

Dereferencing a null pointer is how this dungeon got its name.

## Bump to attack

The classic roguelike control scheme: walking into a monster is attacking it.
One key, two meanings, decided by what is there.

```
if (target != nullptr)      attack it, and do not move
else if (isWall(nx, ny))    blocked
else                        move
```

## Your task

`dice.*` and `dungeon.*` are done. `monster.h`, `game.h` and `main.cpp` are
written for you - read all three before you start. You write `monster.cpp`
and `game.cpp`.

> Every capstone floor hands you the reference version of the previous floor,
> so a wobble on floor 22 cannot sink floor 25. Your own floor 22 `main.cpp`
> is still in its own workspace folder if you want it.

**monster.cpp** - the constructor, the getters, `takeDamage` (never below 0),
`isAlive`, the base `cry()` returning `...` and base `damageRoll()` returning
`roll(attack_)`, then:

| class  | name     | glyph | hp | attack | cry     | damageRoll     |
|--------|----------|-------|----|--------|---------|----------------|
| Goblin | "goblin" | `g`   | 12 | 3      | `yip!`  | *inherited*    |
| Ogre   | "ogre"   | `O`   | 30 | 6      | `GRAAA` | `roll(6) + 3`  |

**game.cpp** - the constructor places the hero at the dungeon start with 30 hp
and creates three monsters, in this order:

```
Goblin at 4,5
Goblin at 9,9
Ogre   at 14,10
```

`draw()` prints the map with living monsters drawn over the terrain and the
hero over everything, then a status line:

```
hp 30/30   steps 0   monsters alive 3
```

`run()` prints the two header lines, draws once, then loops over input:

- `q` -> `you climb back out.` and stop
- `w` `a` `s` `d` -> `step(0,-1)`, `step(-1,0)`, `step(0,1)`, `step(1,0)`
- anything else -> `you cannot do that.` and nothing else happens

`step(dx, dy)`:

- a living monster on the target square -> you attack it for `roll(6) + 2`:
  `you hit the goblin for 7 (goblin hp 5)`, and if it died, `the goblin dies`.
  You do **not** move.
- otherwise a wall -> `a wall blocks you`, and the turn does not happen at all
- otherwise -> move, count a step, `you step east`

After a move or an attack (but not after a blocked bump, and not after
nonsense), `monstersAct()` runs: every living monster orthogonally adjacent to
the hero hits for its `damageRoll()`:

```
the goblin hits you for 3 (hp 27)
```

If that takes the hero to 0, print `you die in the dark.` and stop the game
immediately - no more drawing.

Then `draw()`.

At the end, whatever happened, print `steps taken: <n>`.

> Play it before you check it. Go and find the ogre at the bottom right - it
> hits for `roll(6) + 3` and you have 30 hp, so that fight is a real decision.
