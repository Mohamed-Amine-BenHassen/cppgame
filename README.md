# Tower of Turing

A game you play to learn C++.

You climb a tower. Each floor has a guardian, and the only way to hurt it is
to write C++ that works. Your code is compiled by a real compiler and run
against real tests - the moment you hit **save**, the game rebuilds it and
the guardian takes damage for every trial you just made pass.

Twenty-five floors. By the top you will have written a playable dungeon
crawler - about 700 lines across eleven files - yourself.

## Get the game

```
git clone https://github.com/Mohamed-Amine-BenHassen/cppgame.git
cd cppgame
```

Windows only for now. You need a C++ compiler - see [Requirements](#requirements)
below; the game finds Visual Studio's compiler on its own, so there is
nothing else to set up.

## Play

```
.\play.cmd
```

That is the whole interface. Everything else happens inside the game.

## Controls

**In the tower**

| key | |
|---|---|
| `W` `A` `S` `D` or arrows | walk between doors |
| `ENTER` | go into a floor |
| `Q` | leave the tower |

**Reading a lesson**

| key | |
|---|---|
| `SPACE` | next page |
| `B` | back a page |
| `T` | skip to the fight |
| `ESC` | back to the tower |

**Fighting a guardian**

| key | |
|---|---|
| *just save your file* | the game rebuilds and strikes |
| `E` | reopen the editor |
| `R` | strike again without saving |
| `H` | one more whisper (hint) |
| `B` | re-read the lesson |
| `L` | see the answer |
| `ESC` | flee |

## How a fight works

The guardian's hit points are the number of trials on that floor.

- your code does not compile -> it is **SHIELDED**, you do no damage, and the
  first compiler error is shown to you
- it compiles but breaks a rule of the floor (floor 12 wants a real
  `std::vector<Monster>`, floor 20 forbids `delete`) -> the shape is wrong,
  no damage
- it compiles and some trials pass -> that many points of damage, and you are
  told the first line where your output differs from what was wanted
- every trial passes -> the guardian breaks apart, you take the XP, the next
  floor unlocks

You write your code in `workspace\<floor>\`. The game opens it for you.
Nothing else in the folder is yours to edit.

## The climb

**ACT I - The Foundation** - output, variables, input, branching
**ACT II - The Loops** - while, for, seeded dice, vectors
**ACT III - The Toolsmith** - functions, references, structs
**ACT IV - The Architect** - strings, classes, const, inheritance
**ACT V - The Deep Craft** - files, maps, multi-file builds, RAII
**ACT VI - Your Own Game** - five floors that build one dungeon crawler

Each act ends with a boss worth double. Clearing all 25 lands you on exactly
3100 XP, which is precisely the rank of Engine Architect.

## Requirements

A C++ compiler. This machine has Visual Studio's and the game finds it by
itself, so there is nothing to set up. Without one, the game says so on
startup and tells you what to install.

## Notes

- The dice in this game are seeded on purpose. Everyone gets the same rolls,
  which is why the trials can check your combat logs - and why your bugs are
  reproducible.
- Trials compare output character for character. Spacing counts.
- Reading the answer is allowed. Retyping it beats pasting it.

## For maintainers

```
.\play.cmd verify                       every reference solution still passes
.\play.cmd reset <n>                    restore one floor to its starter code
.\play.cmd demo "enter,k,enter,t,esc"   drive the UI with canned keys, print frames
pwsh -File engine\Build-Expected.ps1    regenerate every expected output
pwsh -File engine\Test-Starters.ps1     every starter must still FAIL
```
