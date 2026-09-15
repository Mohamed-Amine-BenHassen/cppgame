# FLOOR 9 - Spells as Functions

You have been calling `roll()` for three floors without knowing how it works.
Today you build your own.

A function is a piece of work with a name, an entrance and an exit. That is
all it is - and it is the single biggest jump in how large a program you can
hold in your head.

## The shape

```
int attackDamage(int strength) {
    return roll(6) + strength / 2;
}
```

- `int` at the front - what it hands **back**
- `attackDamage` - what you call it
- `(int strength)` - what you must hand **in**
- `return` - the value that comes out, and the instant exit

Call it like any value you have used:

```
int d = attackDamage(6);
```

## void

Some work produces no answer, only an effect - printing, for instance.
Those return `void`, and you just let them end:

```
void shout(const std::string& text) {
    std::cout << text << "!\n";
}
```

## Two rules that will trip you

**Define before you call.** C++ reads your file top to bottom. A function
must appear above whatever calls it - so your functions go between `roll()`
and `main()`.

**Parameters are local copies.** `strength` inside the function is not the
same box as the `strength` outside it. Changing it changes nothing out
there. That is not a limitation, it is a safety rail - and floor 10 is about
the door in that rail.

## Your task

Write exactly three functions, then use them.

```
int attackDamage(int strength)
```
returns `roll(6) + strength / 2`. (`strength / 2` is integer division - a
strength of 7 adds 3, not 3.5.)

```
bool isDead(int hp)
```
returns true when hp is 0 or below.

```
void showBar(const std::string& name, int hp, int maxHp)
```
prints one line: the name, a ten-cell bar, and the numbers.

```
ogre [######....] 18/30
```

The bar has exactly ten cells. Filled cells are `#`, empty ones are `.`,
and the count is `hp * 10 / maxHp` - except that a dead thing shows zero
filled cells rather than a negative number.

## Then, in main

The hero has strength 6. The ogre has 30 hp out of 30.

1. print `-- the ogre blocks the stair --`
2. `showBar` the ogre
3. for three rounds, numbered 1 to 3:
   - work out the damage with `attackDamage(6)`
   - take it off the ogre
   - print `round <n>: you deal <d>`
   - `showBar` the ogre again
4. finally, print `the ogre is down` if `isDead` says so, otherwise
   `the ogre still stands`

The first lines come out like this:

```
-- the ogre blocks the stair --
ogre [##########] 30/30
round 1: you deal 7
ogre [#######...] 23/30
```
