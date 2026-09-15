# FLOOR 11 - The Monster Blueprint

A goblin is a name, an amount of health, and an attack value. Three
variables that belong together. Right now your only option is:

```
std::string goblinName = "goblin";
int goblinHp = 12;
int goblinAttack = 3;
```

Now add an ogre. Now add twelve more. Now pass one to a function - all
three pieces, every time, in the right order. The idea "a monster" exists
in your head but nowhere in your code, and that gap is where bugs live.

## struct

```
struct Monster {
    std::string name;
    int hp;
    int attack;
};
```

That is a new **type**, as real as `int`. It says: a Monster is these three
things, always, together. Note the semicolon after the closing brace. C++
wants it and will be unpleasant about it.

## Using one

```
Monster goblin{"goblin", 12, 3};    // in declaration order

goblin.hp -= 5;                     // the dot reaches inside
std::cout << goblin.name;
```

## Structs through functions

Everything you learned on floor 10 applies, and matters more, because a
struct is bigger than an int:

```
void describe(const Monster& m)     // only looking - cheap, and safe
void wound(Monster& m, int amount)  // changing the caller's monster
```

This is the moment your code starts describing the *game* instead of
describing memory.

## Your task

Declare the `Monster` struct exactly as above, then write three functions:

```
void describe(const Monster& m)
```
prints one line: `<name>  hp <hp>  atk <attack>` - two spaces before `hp`
and two before `atk`.

```
bool alive(const Monster& m)
```
true when the monster's hp is above 0.

```
void wound(Monster& m, int amount)
```
takes hp off, never below 0.

In main, make two monsters - `goblin` with 12 hp and 3 attack, and `ogre`
with 30 hp and 7 attack - and produce exactly this:

```
-- the room --
goblin  hp 12  atk 3
ogre  hp 30  atk 7
you swing at the goblin for 9
goblin  hp 3  atk 3
goblin alive: yes
you swing at the goblin for 9
goblin  hp 0  atk 3
goblin alive: no
the ogre turns to face you
ogre  hp 30  atk 7
```

Both swings do 9 damage. The second one takes the goblin from 3 to 0, not
to -6, because `wound` has a floor.
