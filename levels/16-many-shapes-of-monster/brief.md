# FLOOR 16 - Many Shapes of Monster   [BOSS]

You want a goblin, an ogre and a wraith in one list, and you want to write
the fight loop **once**. They are different types. A `std::vector<Goblin>`
cannot hold an ogre.

This is the problem inheritance exists to solve, and it is the last big idea
in the object half of C++.

## A Monster, and kinds of Monster

```
class Monster {
public:
    Monster(std::string name, int hp) : name_(name), hp_(hp) {}
    virtual ~Monster() = default;

    virtual std::string cry() const { return "..."; }
    virtual int attackRoll() const { return roll(4); }

    void takeDamage(int a) { hp_ -= a; if (hp_ < 0) hp_ = 0; }
    bool isAlive() const { return hp_ > 0; }
    const std::string& name() const { return name_; }
    int hp() const { return hp_; }

protected:
    std::string name_;
    int hp_;
};

class Goblin : public Monster {
public:
    Goblin() : Monster("goblin", 12) {}
    std::string cry() const override { return "yip!"; }
    int attackRoll() const override { return roll(4) + 1; }
};
```

Three new pieces of syntax:

- `: public Monster` - a Goblin **is a** Monster, and inherits everything.
- `: name_(name), hp_(hp)` after the constructor's parentheses is an
  **initialiser list**. It builds the members directly instead of default-building
  them and then assigning. `Goblin() : Monster("goblin", 12) {}` uses it to
  hand values up to the base class - which is the only way to do that.
- `protected:` - like private, except derived classes may also reach it.

## virtual and override

`virtual` says: a derived class is allowed to replace this. `override` says:
I am replacing something - and please check that I spelled it right. Without
`override`, a typo silently creates a brand new unrelated method and your
goblin quietly uses the base version forever. Always write it.

## Pointers, briefly

To keep different kinds in one vector, you store **addresses**:

```
std::vector<Monster*> horde;
horde.push_back(new Goblin());
```

- `Monster*` - "the address of some Monster"
- `new Goblin()` - build one that outlives this scope, hand back its address
- `m->cry()` - the dot, for pointers
- `delete m;` - hand the memory back

And here is the magic: `m` is a `Monster*`, but `m->cry()` runs **Goblin's**
version. The decision happens at run time, based on what the object really
is. One loop, three behaviours. That is **polymorphism**.

## The virtual destructor

```
virtual ~Monster() = default;
```

Deleting a Goblin through a `Monster*` when the destructor is not virtual is
undefined behaviour - the wrong destructor runs. Rule: **the moment a class
has one virtual function, give it a virtual destructor.**

Every `new` needs exactly one `delete`. Miss one and you have leaked memory.
Doing this by hand is tedious and error-prone, which is exactly why floor 20
exists.

## Your task

Build `Monster` as above, then three kinds:

| class  | name     | hp | cry         | attackRoll        |
|--------|----------|----|-------------|-------------------|
| Goblin | "goblin" | 12 | `yip!`      | `roll(4) + 1`     |
| Ogre   | "ogre"   | 30 | `GRAAA`     | `roll(6) + 3`     |
| Wraith | "wraith" | 8  | `(silence)` | *does not override* |

Wraith inherits the base `attackRoll` - do not give it one.

In main, put one of each into a `std::vector<Monster*>`, in that order, then:

1. print `-- the horde --`
2. for each: `<name>: <cry>`
3. print `-- they strike --`
4. for each: `<name> strikes for <attackRoll()>`
5. print `-- you answer --`
6. for each: 15 damage, then `<name> takes 15 (hp <left>)`, and if it died,
   a second line: two spaces, then `<name> is gone`
7. print `survivors: <count still alive>`
8. `delete` every one of them

Expected:

```
-- the horde --
goblin: yip!
ogre: GRAAA
wraith: (silence)
-- they strike --
goblin strikes for 5
ogre strikes for 6
wraith strikes for 2
-- you answer --
goblin takes 15 (hp 0)
  goblin is gone
ogre takes 15 (hp 15)
wraith takes 15 (hp 0)
  wraith is gone
survivors: 1
```
