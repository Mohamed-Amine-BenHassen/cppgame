# FLOOR 17 - The Save Stone

Everything your programs have ever done vanished the moment they exited.
A game needs to remember. Files are how.

The good news: you already know the syntax. A file stream is `cout` and
`cin` pointed somewhere else.

## Writing

```
#include <fstream>

std::ofstream out("save.txt");
out << "Kaelen\n";
out << 28 << " " << 40 << "\n";
```

`ofstream` is an **o**utput file stream. Opening it this way wipes the file
and starts fresh. You never close it - when `out` goes out of scope, it
closes itself. (Hold on to that. It is floor 20's whole subject.)

## Reading

```
std::ifstream in("save.txt");
int hp, maxHp;
in >> hp >> maxHp;
```

Same `>>`, same rules - including the newline trap from floor 13. If you
read numbers with `>>` and then want a whole line, clear the leftover first:

```
in >> count;
in.ignore(10000, '\n');
std::getline(in, item);
```

## Files that are not there

This is the part beginners skip and then spend an evening on. Opening a
missing file is **not** a crash. You get a stream that quietly fails, and
every read from it does nothing, leaving your variables holding garbage.

```
std::ifstream in("missing.txt");
if (!in) {
    std::cout << "no save file found\n";
}
```

Check every file you open. Always.

## Designing a format

A save file is a promise between the writer and the reader. Keep it dull and
obvious. Ours:

```
Kaelen          <- name, a whole line
28 40           <- hp and maxHp
137             <- gold
3               <- how many items follow
torch           <- the items, one per line
rope
iron key
```

The count line is the important idea: the reader must know how many items to
expect before it starts reading them.

## Your task

Three parts, in one program.

**Part 1** - write exactly the file above to `save.txt`, from these values:
name `Kaelen`, hp 28, maxHp 40, gold 137, and the three items `torch`,
`rope`, `iron key`. Then print:

```
saved to save.txt
```

**Part 2** - open `save.txt` fresh, read it all back into new variables, and
print:

```
-- loaded --
Kaelen 28/40
gold: 137
items: 3
  torch
  rope
  iron key
```

Read it back properly - do not print the variables you already had. The
point is the round trip.

**Part 3** - try to open `missing.txt`, check it, and print:

```
missing.txt: no save file found
```

The item lines in part 2 have two leading spaces. `iron key` has a space in
it, so those must come back with `getline`, not `>>`.
