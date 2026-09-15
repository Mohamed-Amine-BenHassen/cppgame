# FLOOR 18 - The Bestiary

To find something in a vector you walk the whole thing. Twenty items, fine.
Twenty thousand, every frame, and your game is a slideshow.

When you want to look things up **by name**, you want a map.

## std::map

```
#include <map>

std::map<std::string, int> hoard;

hoard["rat"] = 3;
hoard["bat"] = 1;

std::cout << hoard["rat"];      // 3
std::cout << hoard.size();      // 2
```

Two type arguments: the **key** you look up by, and the **value** you get
back. Lookup does not scan - it goes more or less straight there.

A `std::map` also keeps its keys **sorted**. Print one and it comes out
alphabetically without you asking. (`std::unordered_map` is faster and does
not sort. Use that when you do not care about order.)

## Walking a map

Each entry is a pair:

```
for (const auto& entry : hoard) {
    std::cout << entry.first << " x" << entry.second << "\n";
}
```

`first` is the key, `second` is the value. Since C++17 you can unpack them
into real names, which is much easier to read:

```
for (const auto& [name, count] : hoard) {
    std::cout << name << " x" << count << "\n";
}
```

`auto` means "compiler, you work out the type". Here the type is a long
mouthful and `auto` is the normal choice.

## The trap: operator[] inserts

```
if (hoard["dragon"] > 0) { ... }
```

If `dragon` was not in the map, that line just **created** it, with value 0.
Your map grew a key by being asked a question. That is how a size count
slowly drifts wrong and nobody knows why.

To ask without inserting, use `find`:

```
auto it = hoard.find("dragon");
if (it == hoard.end()) {
    // not there
} else {
    std::cout << it->second;      // it is a pointer-ish thing, so ->
}
```

`end()` is "one past the last entry" - the universal C++ way of saying not
found.

Counting is the one place `hoard[name]++` is exactly right: you *want* a
missing key to spring into being as 0 and then become 1.

## Your task

Read item names, one per line, until `done`. Count how many times each one
appears, in a `std::map<std::string, int>`.

If nothing came in, print just this and stop:

```
the hoard is empty
```

Otherwise print:

```
-- hoard --
  <name> x<count>          (every entry, alphabetical - the map does this)
distinct: <how many different names>
total: <how many items altogether>
rat: <count, or "none">
gold coin: <count, or "none">
```

Those last two are **lookups done with `find`**, so that asking about
something absent does not add it. Print the number when it is there and the
word `none` when it is not.

For input `rat, bat, rat, gold coin, rat, bat, done`:

```
-- hoard --
  bat x2
  gold coin x1
  rat x3
distinct: 3
total: 6
rat: 3
gold coin: 1
```

Names can contain spaces, so read them with `getline`.
