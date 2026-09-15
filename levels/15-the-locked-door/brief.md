# FLOOR 15 - The Locked Door

Floor 14 locked the data away. This floor is about the two things that make
that lock worth having: **invariants**, and **const**.

## An invariant is a promise

An invariant is something about your object that is true the moment it is
born and true after every method, no matter what anyone does to it.

- a Hero's hp is never below 0, never above maxHp
- a Pack never holds more than its capacity

Once a promise like that is enforced *inside* the class, every piece of code
outside can stop worrying about it. That is the actual payoff of
encapsulation - not secrecy, but the fact that there is exactly **one** place
that can break each rule, so there is exactly one place to look.

## Failure is a return value

What should `add` do when the pack is full? Not crash, and not silently
pretend. It should say so:

```
bool add(const std::string& item);   // false = did not fit
```

The caller decides what that means. Refuse cleanly and change nothing - a
method that half-succeeds is worse than one that says no.

## const, and why it spreads

```
void report(const Pack& p) {
    std::cout << p.size();     // only compiles if size() is const
}
```

`p` is a `const Pack&` - a promise that `report` will not change the pack.
So the compiler will only let it call methods that made the same promise.
One missing `const` on `size()` and this function will not build.

That is why const seems to spread through a codebase: it is not a style,
it is a chain of promises, and every link has to hold. Mark every
read-only method `const` and the chain builds itself.

## Your task

Write a `Pack` class:

```
Pack(size_t capacity)
bool add(const std::string& item)     // false if already full
bool drop(const std::string& item)    // false if it is not in there
bool has(const std::string& item) const
bool full() const
size_t size() const
size_t capacity() const
std::string list() const              // "torch, rope" or "(empty)"
```

Data: a `std::vector<std::string> items_` and a `size_t capacity_`, both
private.

Then a free function, outside the class:

```
void report(const Pack& p)
```

which prints two lines - `-- pack (<size>/<capacity>) --` and then
`p.list()`.

In main, make a `Pack pack(3);` and produce exactly this:

```
-- pack (0/3) --
(empty)
add torch -> yes
add rope -> yes
add rations -> yes
add lantern -> no
-- pack (3/3) --
torch, rope, rations
has rope: yes
drop rope -> yes
drop rope -> no
has rope: no
-- pack (2/3) --
torch, rations
```

The separator in `list()` is a comma followed by one space, and there is no
trailing comma. Getting that right is a five-minute fight the first time and
then a reflex forever.
