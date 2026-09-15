# FLOOR 3 - Naming the Hero

A game nobody can talk to is a screensaver. Time to read input.

## Two ways in

`std::cin` is the mirror image of `std::cout`. The arrows flip around,
because now data is flowing *out of* the input and *into* your variable:

```
int level;
std::cin >> level;          // read one number
```

`>>` stops at the first space. That is fine for numbers, and useless for
names, because `Grim the Unwashed` would only give you `Grim`. For a whole
line, use `getline`:

```
std::string name;
std::getline(std::cin, name);   // reads everything up to the Enter key
```

## Prompting

The player cannot read your mind, so print a prompt first:

```
std::cout << "What shall we call you?\n";
std::getline(std::cin, name);
```

That is the entire loop of interactive software: print, read, respond.

## Your task

Ask two questions, read the answers, and print a small hero summary.

1. print `What shall we call you?` then read a whole line into a string
2. print `How many floors have you climbed?` then read an int
3. print a blank line
4. print `<name>, level <n>`
5. print `max health: <80 + n * 20>`
6. print `next level at: <n * 100> xp`

With the player typing `Kaelen` and then `7`, the whole run looks like:

```
What shall we call you?
How many floors have you climbed?

Kaelen, level 7
max health: 220
next level at: 700 xp
```

> The prompts and the answers look interleaved when you type them yourself -
> that is just your keyboard echoing. The trials feed input from a file, so
> only your program's own output is compared.

## Try it yourself first

```
.\play.ps1 run
```

Type an answer, press Enter. That is your program listening to you.
