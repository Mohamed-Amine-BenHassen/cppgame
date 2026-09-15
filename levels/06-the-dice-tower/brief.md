# FLOOR 6 - The Dice Tower

Games need luck. Computers cannot do luck, so they fake it - very well, and
completely predictably. Today you meet both halves of that.

## for

A `while` loop that counts always has the same three moving parts, so C++
gives you a way to put all three on one line:

```
for (int i = 1; i <= 10; ++i) {
    std::cout << i << "\n";
}
```

- `int i = 1` runs once, before anything
- `i <= 10` is checked before every pass
- `++i` runs after every pass

Use `for` when you know how many times. Use `while` when you are waiting for
something to happen. That is the whole rule.

`i` only exists inside the loop. Anything you want to survive - a total, a
counter - must be declared **above** the loop.

## Dice that repeat themselves

Your `main.cpp` already contains this, as a gift:

```
unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}
```

You will learn to write functions like that on floor 9. For now, just call
it: `roll(6)` gives you 1 to 6, `roll(20)` gives you 1 to 20.

It is not really random. It stirs one number (`rngState`) with arithmetic and
serves you a slice of the result. Same starting state, same sequence, every
single run. That sounds like a flaw and it is a gift: your game is replayable,
your bugs are reproducible, and the trials can check your dice.

`%` is the leftover after division - `17 % 5` is `2`. It is how you squeeze a
huge stirred number down into the range 0..sides-1. The `+ 1` shifts it to
1..sides, because dice do not have a zero.

## Your task

Roll a six-sided die ten times. For each roll, print:

```
roll <n>: <value>
```

Count how many rolls were **4 or higher** (a hit), and add every roll into a
running total. When the loop is done, print:

```
hits: <h> of 10
damage: <total>
```

Because the dice are seeded, everyone's answer is the same one. Roll it
once per pass - `roll()` changes the state every time you call it, so
calling it twice in one pass gives you two different numbers and a log
that disagrees with your own total.
