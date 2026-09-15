# FLOOR 20 - The Weight of Memory   [BOSS]

Floor 16 ended with this:

```
for (Monster* m : horde) {
    delete m;
}
```

It works. It also has to be right *every single time*, including the times
you return early, and the times something throws halfway through. Miss one
and the memory is gone until the program exits. This is the single largest
source of serious bugs in C and C++.

Modern C++ mostly deleted the problem instead of solving it.

## RAII

The idea has a terrible name and is one of the best in the language:

> a thing that owns a resource releases it in its destructor

The destructor runs **automatically** when the object goes out of scope.
Not when you remember. Not on the happy path only. Always.

```
class Torch {
public:
    Torch(std::string where) : where_(where) {
        std::cout << "you light the torch in the " << where_ << "\n";
    }
    ~Torch() {
        std::cout << "the torch gutters out in the " << where_ << "\n";
    }
private:
    std::string where_;
};
```

`~Torch()` is the destructor - the class's name with a tilde. You have been
relying on this for floors: that is how every `std::string`, `std::vector`
and `std::ofstream` you have used cleaned itself up.

Objects are destroyed in **reverse** order of creation. First lit, last out.

## unique_ptr

Now apply RAII to the horde:

```
#include <memory>

std::vector<std::unique_ptr<Monster>> horde;
horde.push_back(std::make_unique<Goblin>());
```

A `unique_ptr` is a pointer that owns what it points at, and deletes it when
it dies. `make_unique<Goblin>()` builds a Goblin and hands over ownership.
No `new`, no `delete`, no leak - it is not possible to forget.

It still behaves like a pointer: `m->cry()` works exactly as before.

## Unique means unique

You cannot copy a `unique_ptr`. Two owners would both try to delete, so the
language refuses. To hand ownership over, you **move** it:

```
survivors.push_back(std::move(m));
```

After that line, `m` is empty and `survivors` owns the monster. Exactly one
owner, always. That is why your loops need `auto&` and not `auto` - a plain
`auto` would try to copy, and the compiler will stop you.

`m.reset()` destroys what a unique_ptr holds immediately. On one that has
already been moved from, it does nothing, because there is nothing left.

## Your task

Take floor 16's monsters, drop `attackRoll` (no dice today), and give the
base class a destructor that announces itself:

```
virtual ~Monster() { std::cout << "  " << name_ << " dissolves\n"; }
```

Keep `cry()` virtual: goblin `yip!`, ogre `GRAAA`, wraith `(silence)`.
Keep hp: goblin 12, ogre 30, wraith 8. Write the `Torch` class as above.

In main, in this order:

1. `Torch torch("hall");` - first, so it dies last
2. a `std::vector<std::unique_ptr<Monster>> horde` with a Goblin, an Ogre and
   a Wraith, made with `make_unique`
3. print `-- the horde --`, then `<name>: <cry>` for each
4. print `-- you answer --`, then hit each for 15: `<name> takes 15 (hp <left>)`
5. print `-- the dead are cleared --`, then move every *living* monster into a
   second vector `survivors`, and afterwards `reset()` each pointer in `horde`
   in order
6. print `survivors: <count>`
7. print `-- you leave --`

Then just let main end. Write no `delete` at all.

```
you light the torch in the hall
-- the horde --
goblin: yip!
ogre: GRAAA
wraith: (silence)
-- you answer --
goblin takes 15 (hp 0)
ogre takes 15 (hp 15)
wraith takes 15 (hp 0)
-- the dead are cleared --
  goblin dissolves
  wraith dissolves
survivors: 1
-- you leave --
  ogre dissolves
the torch gutters out in the hall
```

Look at the last three lines. Nothing in your code printed them at that
point. The ogre dissolves because `survivors` went out of scope, and the
torch goes out after it because it was made first. You wrote no cleanup and
nothing leaked.

That is the floor. Everything above this one is now yours to build with.
