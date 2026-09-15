# FLOOR 7 - The Combat Round

Loops, conditions and dice, in one room. This is a real combat system -
small, but the same shape as one in a real game.

## Loops that end when something happens

Not every loop counts. Some wait for a state to change:

```
while (heroHp > 0 && goblinHp > 0) {
    // one round
}
```

The loop stops the moment either fighter drops. But there is a subtlety:
the condition is only checked **between** rounds. If the hero kills the
goblin halfway through a round, the goblin still gets its swing, because the
code below has not run out yet.

`break` is the fix. It leaves the loop immediately, from anywhere inside:

```
if (goblinHp <= 0) {
    break;
}
```

Order of operations inside a turn is a design decision, and it is the kind
of thing that decides whether a fight feels fair.

## Your task

A hero (30 hp) fights a goblin (22 hp). Rounds repeat while both live.

Each round, in this order:

1. count the round
2. print `-- round <n> --`
3. the hero swings for `roll(6) + 2`, print `you hit the goblin for <d> (goblin hp <left>)`
4. if the goblin is at 0 or below, `break` out - a dead goblin does not swing
5. the goblin swings for `roll(4) + 1`, print `the goblin hits you for <d> (your hp <left>)`

When the fight is over, print one line:

- if the hero survived: `the goblin falls. you live, on <hp> hp.`
- otherwise: `you fall. the dungeon keeps your gold.`

The opening looks like this:

```
-- round 1 --
you hit the goblin for 6 (goblin hp 16)
the goblin hits you for 2 (your hp 28)
-- round 2 --
```

> The dice are the same seeded `roll()` from floor 6, so this fight plays out
> identically for everyone. If your log drifts from the expected one, count
> your `roll()` calls - an extra call anywhere shifts every number after it.
