# FLOOR 12 - A Room Full of Monsters   [BOSS]

Floor 8 gave you a vector of strings. Floor 11 gave you a Monster. Put them
together and you have the thing every game is actually made of: a list of
entities you loop over, change, and ask questions about.

## A vector of structs

```
std::vector<Monster> room;
room.push_back(Monster{"goblin", 12, 3});
```

## The trap that will get you

```
for (Monster m : room) {      // m is a COPY
    wound(m, 5);              // the copy takes damage
}                             // the copy is destroyed. room is untouched.
```

```
for (Monster& m : room) {     // m is the real one
    wound(m, 5);              // the room actually changes
}
```

One character. This is floor 10's lesson in a different coat, and it is worth
meeting twice, because when it bites you in real code it looks like the
computer is ignoring you.

Use `const Monster&` when you are only reading, `Monster&` when you are
changing. Say what you mean and the compiler will hold you to it.

## Your task

Read monsters from input. Each is a name, an hp and an attack:

```
goblin 12 3
ogre 30 7
rat 4 1
done
```

The word `done` on its own ends the list. Names never contain spaces, so
`std::cin >>` is fine here.

`describe`, `alive` and `wound` from floor 11 are already in your starter
file. Use them.

Then print, in this order:

1. `-- ROOM (<n> monsters) --`
2. every monster, via `describe`
3. `total threat: <sum of every attack value>`
4. `toughest: <name of the monster with the most hp>` - on a tie, the first one
5. `-- you sweep the room --`
6. one swing at each monster, in order, for `roll(6) + 3` damage:
   - `you hit <name> for <d> (hp <left>)`
   - and if that killed it, a second line: two spaces, the name, ` dies`
7. `still standing: <how many are still alive>`

If the room is empty, print only this and stop:

```
-- ROOM (0 monsters) --
nothing here but dust
```

For the three monsters above, the sweep begins:

```
-- you sweep the room --
you hit goblin for 7 (hp 5)
you hit ogre for 6 (hp 24)
you hit rat for 7 (hp 0)
  rat dies
```

> One `roll(6)` per monster, in order. An extra call anywhere and every
> number after it shifts.
