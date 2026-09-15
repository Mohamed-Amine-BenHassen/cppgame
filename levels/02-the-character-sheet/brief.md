# FLOOR 2 - The Character Sheet

Printing fixed text is a party trick. A game needs numbers that change:
health that drops, gold that grows. That means **variables**.

## A variable is a labelled box

```
int gold = 25;
```

Three parts: the **type** (`int`), the **name** (`gold`), the **starting
value** (`25`). From then on, the word `gold` means whatever is in the box.

```
gold = gold + 17;      // read the box, add 17, put it back
gold += 17;            // exactly the same thing, written shorter
```

## The types you need today

- `int` - whole numbers. Health, gold, damage. `int health = 100;`
- `double` - numbers with a fractional part. `double crit = 0.15;`
- `char` - exactly one character, in SINGLE quotes. `char rank = 'R';`
- `bool` - true or false, nothing else. `bool alive = true;`
- `std::string` - text. Needs `#include <string>` at the top. `std::string name = "Kaelen";`

## Two things that will bite you

**Bools print as numbers.** `std::cout << alive;` prints `1`, not `true`.
A bool really is 1 or 0 underneath. Later you will learn to print it nicely.

**Integer division throws away the remainder.** `7 / 2` is `3`, not `3.5`,
because both sides are ints. If you want `3.5` you need a `double` involved.
This one catches everybody, usually at 2am.

## Your task

Build a character sheet out of variables, not out of hardcoded text.
These are the **starting** facts:

- the hero is named `Kaelen`, and their class letter is `R`
- health starts at `120`, then a trap takes `20` off it
- gold starts at `25`, then they find `17` more
- strength is `5`, and attack damage is `strength * 2 + 3`
- crit chance is `0.15`
- the hero is alive

Print exactly this:

```
-- CHARACTER SHEET --
name: Kaelen
class: R
health: 100
gold: 42
attack: 13
crit: 0.15
alive: 1
```

> The trial checks your source too: the numbers `100`, `42` and `13` must not
> appear anywhere in your code. You have to make the program work them out.
> That is the whole point - a game where the health is typed in by hand is not
> a game.
