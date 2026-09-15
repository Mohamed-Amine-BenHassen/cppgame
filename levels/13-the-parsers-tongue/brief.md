# FLOOR 13 - The Parser's Tongue

A player types `take rusty key`. Your game has to turn that sentence into a
verb, a thing, and an action. That is parsing, and it is the seam between a
human and a program.

## The string toolbox

```
std::string line = "take torch";

line.size()            // 10
line.empty()           // false
line.find(' ')         // 4  - position of the first space
line.substr(0, 4)      // "take"
line.substr(5)         // "torch"  - from 5 to the end
```

`substr(start, count)` takes `count` characters. `substr(start)` takes
everything from there on. Mixing those two up is most of what goes wrong
with strings.

## npos

What does `find` return when there is no space at all?

```
std::string::npos
```

A special "nowhere" value. You must check for it, because `substr` given a
nonsense position will throw:

```
size_t space = line.find(' ');
if (space == std::string::npos) {
    verb = line;          // the whole line is the verb
    rest = "";
} else {
    verb = line.substr(0, space);
    rest = line.substr(space + 1);
}
```

## The pitfall you were promised on floor 3

```
std::cin >> level;                  // reads 7, leaves the Enter key sitting there
std::getline(std::cin, name);       // grabs that leftover Enter. Empty string.
```

`>>` stops at whitespace and does not consume the newline. The next
`getline` finds it immediately and returns nothing. The cure:

```
std::cin >> level;
std::cin.ignore(10000, '\n');       // throw away the rest of that line
std::getline(std::cin, name);
```

Today you only use `getline`, so you dodge it. Now you know why the order
mattered back then, and what to do when it does not.

## Your task

Read lines until the line `quit` (or until the input runs out). For each
line, print exactly one response.

- an empty line -> `say something.`
- `look` -> `the room is dark.`
- `go <somewhere>` -> `you walk <somewhere>.`
- `take <thing>` -> `you pocket the <thing>.`
- `go` or `take` with nothing after it -> `<verb> what?`
- anything else -> `you cannot <verb>.`

The `<somewhere>` and `<thing>` are the whole rest of the line, spaces and
all - `go down the stairs` gives `you walk down the stairs.`

When the loop ends, print `you leave the room.` exactly once.

Input:

```
look
go north
take torch
dance
quit
```

Output:

```
the room is dark.
you walk north.
you pocket the torch.
you cannot dance.
you leave the room.
```
