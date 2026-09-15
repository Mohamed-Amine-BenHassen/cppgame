# FLOOR 10 - What the Potion Touches

Last floor ended on a warning: parameters are copies. Today that warning
becomes the whole lesson, because it is the bug every beginner writes.

## The bug

```
void heal(int hp, int amount) {
    hp += amount;             // changes the copy
}

int myHp = 20;
heal(myHp, 30);
std::cout << myHp;            // still 20
```

The function was handed a *photocopy* of `myHp`. It scribbled on the
photocopy and threw it away. Nothing you do to a by-value parameter is
visible outside.

## The fix: a reference

```
void heal(int& hp, int amount) {
    hp += amount;             // changes the caller's actual variable
}
```

One `&` and `hp` stops being a copy - it becomes another name for the very
box the caller passed in. Writing to it writes to theirs.

## const&, and why it is everywhere

References have a second use that has nothing to do with changing things.
Copying a big object - a long string, a vector of 500 monsters - costs real
time. A reference costs nothing, because nothing is copied.

```
void describe(const std::string& name)
```

`const` promises you will only look, never touch. So `const&` means "let me
see the real one, cheaply, and I swear not to break it". For anything bigger
than an int, this is the default you should reach for. You have been reading
it since floor 8 - now you know what it says.

## Your task

Write four functions and drive them from main.

```
void brokenHeal(int hp, int amount)      // by VALUE - deliberately useless
void heal(int& hp, int maxHp, int amount) // by reference, never above maxHp
void wound(int& hp, int amount)           // by reference, never below 0
bool tryBuy(int& gold, int price)         // spends only if affordable
```

`tryBuy` returns true and subtracts the price when there is enough gold.
When there is not, it returns false and leaves the gold alone.

In main, start with `hp = 20`, `maxHp = 60`, `gold = 30`, and print exactly
this sequence:

```
hp 20
brokenHeal 30 -> hp 20
heal 30 -> hp 50
heal 30 -> hp 60
wound 80 -> hp 0
gold 30
buy rope for 10 -> yes, gold 20
buy sword for 50 -> no, gold 20
```

Read those two `heal` lines. The second one asks for 30 more and only gets
10, because 60 is the ceiling. And `brokenHeal` sits there doing nothing at
all, which is the entire point of this floor.
