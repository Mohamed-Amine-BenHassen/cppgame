# FLOOR 5 - The Training Dojo

You can print, store and decide. What you cannot do yet is *repeat*, and
almost everything in a game is repetition: frames, turns, enemies, rounds.

## while

```
int count = 0;
while (count < 3) {
    std::cout << "swing\n";
    ++count;
}
```

Read it as: "as long as this is true, run the block again". Three parts,
and all three have to be there:

1. something set up **before** the loop (`count = 0`)
2. a condition that will eventually become false (`count < 3`)
3. something **inside** that moves toward that (`++count`)

Forget number 3 and the loop runs forever. Your program will hang, the
trials will report it, and you will have written your first infinite loop -
also a rite of passage.

## The shorthands

```
++count;        // add one
xp += 30;       // add 30
xp -= 100;      // take 100 away
```

## Your task

A hero trains until they reach level 5.

Set up: `xp` starts at 0, `level` starts at 1, `session` starts at 0.

Then, while the level is below 5:

- one more session happens, and 30 xp is earned
- print `session <n>: +30 xp (total <xp>)`
- if xp has reached 100 or more, spend 100 of it to gain a level, and print
  `  ** level up ** now level <level> (xp <leftover>)` - note the two leading spaces

When the loop finally ends, print `training done: <sessions> sessions to reach level 5`.

The first few lines look like this:

```
session 1: +30 xp (total 30)
session 2: +30 xp (total 60)
session 3: +30 xp (total 90)
session 4: +30 xp (total 120)
  ** level up ** now level 2 (xp 20)
session 5: +30 xp (total 50)
```

> The leftover matters. At 120 xp you spend 100 and keep 20 - you do not
> throw it away. Getting that right is the difference between a loop that
> models something and a loop that just counts.

Your program has to work out how many sessions it took. Typing the answer in
is forbidden by the trial, and honestly, you do not know it yet either.
