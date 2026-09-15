# FLOOR 8 - The Inventory Rack   [BOSS]

One variable holds one thing. A backpack holds however many things the
player shoves into it, and you do not know that number when you write the
code. You need a container.

## std::vector

```
#include <vector>
#include <string>

std::vector<std::string> pack;    // empty, holds strings
pack.push_back("torch");          // now it holds one
pack.push_back("rope");           // now two
```

The `<std::string>` part says what kind of thing goes in. A
`std::vector<int>` holds ints. It grows by itself - that is the whole point.

```
pack.size()     // how many are in there
pack[0]         // the FIRST one. Counting starts at zero.
pack.back()     // the last one
pack.empty()    // true if there is nothing in it
```

**Zero-based indexing** is the thing to burn in. A vector with 4 items has
valid slots 0, 1, 2 and 3. There is no slot 4. Reaching for one is not an
error message - it is your program quietly reading someone else's memory,
and it is the single most common way C++ programs go wrong.

## Two ways to walk it

When you need the position:

```
for (size_t i = 0; i < pack.size(); ++i) {
    std::cout << i + 1 << ". " << pack[i] << "\n";
}
```

When you only need the things:

```
for (const std::string& item : pack) {
    std::cout << item << "\n";
}
```

The second is a **range-for**. Read it as "for each item in pack". The `&`
means "look at the real one, do not make a copy" - you will meet that
properly on floor 10.

## Your task

Read item names, one per line, until the line `done` arrives. Do not store
`done` itself. Then print the pack.

If nothing was picked up, print exactly one line and stop:

```
your pack is empty
```

Otherwise print:

```
-- PACK (<n> items) --
  1. <first>
  2. <second>
  ...
slots used: <n> of 8
torch: <yes or no>
last picked up: <the final item>
```

Each numbered line starts with two spaces. Items are numbered from 1 for
the human, even though the vector counts from 0 - translating between those
two is your job now.

`torch:` is `yes` only if an item is exactly `torch`.

With input `torch`, `rope`, `rations`, `iron key`, `done`:

```
-- PACK (4 items) --
  1. torch
  2. rope
  3. rations
  4. iron key
slots used: 4 of 8
torch: yes
last picked up: iron key
```
