# FLOOR 1 - Hello, Adventurer

You are standing at the bottom of a very tall tower. At the top is a game.
Not a game someone made for you - one you wrote. Every floor you clear adds a
piece of it.

This floor is the smallest possible piece: making the machine say a thing.

## The shape of every C++ program

```
#include <iostream>

int main() {
    std::cout << "text goes here\n";
    return 0;
}
```

Four things are happening.

- `#include <iostream>` pulls in the toolbox for input and output. Without it, `std::cout` does not exist.
- `int main()` is where your program starts. Every C++ program has exactly one.
- `std::cout << "..."` sends text to the screen. Read `<<` as an arrow pointing where the text goes.
- `return 0;` tells the operating system "I finished, nothing went wrong."

That `\n` is not two characters when it prints. Inside quotes it means **newline** - move to the next line. This is how you control layout.

## Chaining

`<<` can be chained, and this is very normal C++:

```
std::cout << "gold: " << 42 << "\n";
```

That prints `gold: 42` and then a newline. Notice the number has no quotes -
quotes mean "literal text", no quotes means "the value".

## Your task

Open your `main.cpp` and make the program print exactly these four lines:

```
==================================
  DUNGEON OF THE NULL POINTER
==================================
a game you have not written yet
```

Line up the spacing exactly. The trials compare character for character,
which is the first hard habit of programming: the computer does not do
what you meant.

## When you are ready

```
.\play.ps1 run      <- see it with your own eyes
.\play.ps1 check    <- face the trial
```
