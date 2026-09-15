# FLOOR 19 - The Workshop

Every program you have written lived in one file. The game at the top of this
tower will not. Once a file passes a few hundred lines you stop being able to
find anything in it, and every tiny change rebuilds the whole thing.

C++ splits code in two:

- a **header** (`.h`) says *what exists* - the promises
- a **source file** (`.cpp`) says *how it works* - the bodies

Other files include the header. They only ever need the promises.

## The worked example, already in your workspace

`dice.h`:

```
#pragma once

int roll(int sides);
```

That semicolon instead of a body is a **declaration**: "somewhere, there is a
function shaped like this". Enough for anyone who wants to call it.

`dice.cpp`:

```
#include "dice.h"

static unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}
```

That is the **definition**. `main.cpp` says `#include "dice.h"` and can call
`roll()` without knowing or caring how it works.

## #pragma once

`#include` is a literal copy-paste performed by the compiler. If two files
both include `hero.h`, the class gets pasted twice and you get
`class Hero already defined`.

`#pragma once` at the top of every header stops that. Some codebases use the
older spelling instead:

```
#ifndef HERO_H
#define HERO_H
...
#endif
```

Same idea. Use `#pragma once`; recognise the other when you see it.

## Splitting a class

Header - signatures only, each ending in a semicolon:

```
#pragma once
#include <string>

class Hero {
public:
    Hero(std::string name, int maxHp);
    void takeDamage(int amount);
    bool isAlive() const;
private:
    std::string name_;
    int hp_;
    int maxHp_;
};
```

Source - the bodies, each with the class name glued on the front:

```
#include "hero.h"

Hero::Hero(std::string name, int maxHp) {
    name_ = name;
    maxHp_ = maxHp;
    hp_ = maxHp;
}

void Hero::takeDamage(int amount) {
    hp_ -= amount;
    if (hp_ < 0) { hp_ = 0; }
}

bool Hero::isAlive() const {
    return hp_ > 0;
}
```

`Hero::takeDamage` means "the takeDamage that belongs to Hero". `::` is the
scope resolution operator, and you will type it a great deal from here on.

Note `Hero::Hero` - the constructor's name *is* the class name, so it appears
twice. And note that `const` has to be written in **both** places.

## Your task

`main.cpp`, `dice.h` and `dice.cpp` are done. You write the other two.

`hero.h` - declare a `Hero` class with private `name_`, `hp_`, `maxHp_` and
these public members:

```
Hero(std::string name, int maxHp)     // starts at full health
void takeDamage(int amount)           // never below 0
void heal(int amount)                 // never above maxHp_
bool isAlive() const
std::string status() const            // "Kaelen 28/40"
```

`hero.cpp` - define all five, out of line, with `Hero::`.

Do not touch `main.cpp`. It already expects exactly this, and running it
should produce:

```
-- the workshop --
Kaelen 40/40
round 1: takes 6 -> Kaelen 34/40
round 2: takes 5 -> Kaelen 29/40
round 3: takes 6 -> Kaelen 23/40
a potion -> Kaelen 35/40
alive: yes
```

> The game builds every `.cpp` in your workspace folder and links them
> together. Add a new pair of files and they are picked up automatically -
> which is exactly how the capstone is going to be laid out.
