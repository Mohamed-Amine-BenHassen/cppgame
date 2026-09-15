# FLOOR 4 - The Fork in the Road   [BOSS]

Everything so far ran top to bottom, the same way every time. A game has to
*decide*. This is the floor where your program grows a brain stem.

## if / else if / else

```
if (health < 30) {
    std::cout << "critical\n";
} else if (health < 70) {
    std::cout << "wounded\n";
} else {
    std::cout << "healthy\n";
}
```

Read it as a ladder. The first rung that is true runs, and **everything below
it is skipped**. So the order is the logic. If you check `health < 70` first,
a hero on 5 health is merely "wounded" and the critical branch can never fire.

## The comparisons

`<` `>` `<=` `>=` compare. `==` asks "are these equal", `!=` asks "are these
different".

`=` is assignment, `==` is comparison. Writing `if (hp = 0)` does not test
anything - it *sets* hp to 0 and then treats 0 as false. This bug is a rite
of passage. Now you know.

## Combining conditions

```
if (health < 30 && potions > 0)     // both must be true
if (hasKey || hasLockpick)          // either one will do
if (!alive)                         // not alive
```

A bool is already a question's answer, so `if (hasKey)` is complete on its
own - you never need `if (hasKey == true)`.

## Your task

Read three integers, in this order:

- `hp` - the hero's health
- `potions` - how many potions they carry
- `hasKey` - 1 if they hold the iron key, 0 if not

Then print **two** lines.

**Line one** is the status, decided by hp alone:

- below 30 -> `status: critical`
- below 70 -> `status: wounded`
- otherwise -> `status: healthy`

**Line two** is what happens next. Check these in exactly this order:

1. hp is 0 or less -> `You are dead. The dungeon keeps your gold.`
2. hp below 30 and at least one potion -> `You drink a potion. Health back to 100.`
3. hp below 30 and no potions -> `You crawl toward the stairs, bleeding.`
4. hero has the key -> `You unlock the iron door and descend.`
5. anything else -> `You search the room for a key.`

For the input `25 1 0`:

```
status: critical
You drink a potion. Health back to 100.
```

For the input `90 0 1`:

```
status: healthy
You unlock the iron door and descend.
```

> A dead hero on 0 hp is still "critical" - the status line does not care
> about the action line. Two independent questions about the same numbers.
