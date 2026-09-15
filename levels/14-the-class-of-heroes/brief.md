# FLOOR 14 - The Class of Heroes

Your `Monster` struct works, but nothing stops this:

```
goblin.hp = -9999;
```

The struct is a bag of variables and anyone can reach in. Every rule about
what a monster *is* - hp never below zero, never above max - lives scattered
in whatever functions happen to remember. Miss one and the game quietly
breaks.

A **class** fixes that by putting the data and the rules in the same box, and
then locking the box.

## The shape

```
class Hero {
public:
    Hero(std::string name, int maxHp) {
        name_ = name;
        maxHp_ = maxHp;
        hp_ = maxHp;
    }

    void takeDamage(int amount) {
        hp_ -= amount;
        if (hp_ < 0) { hp_ = 0; }
    }

    bool isAlive() const {
        return hp_ > 0;
    }

private:
    std::string name_;
    int hp_;
    int maxHp_;
};
```

- `public:` - what the outside world may use
- `private:` - what only the class itself may touch. This is the lock.
- the **constructor** shares the class's name, has no return type, and runs
  automatically when a Hero is made

`hp_` cannot be set to -9999 from outside, because there is no way in.
The only route is `takeDamage`, which has the rule built in. That is
**encapsulation**: the object protects its own promises.

## const methods

```
bool isAlive() const
```

That `const` after the parentheses is a promise: *this method does not
change the object*. The compiler enforces it - try to assign to `hp_`
inside a const method and it refuses to build. Put it on every method that
only reads. It is free, and it makes the class self-documenting.

## Using it

```
Hero h("Kaelen", 40);
h.takeDamage(12);
std::cout << h.status() << "\n";
```

The constructor arguments go right after the name. From then on it is just
dots, as with a struct - but now only the doors the class chose to open.

## Your task

Write a `Hero` class with private `name_`, `hp_` and `maxHp_`, and exactly
these public members:

```
Hero(std::string name, int maxHp)   // starts at full health
void takeDamage(int amount)         // never below 0
void heal(int amount)               // never above maxHp_
bool isAlive() const
std::string status() const          // "Kaelen 28/40"
```

`status` **returns** a string, it does not print one. Build it with
`std::to_string` and `+`.

In main, make `Hero kaelen("Kaelen", 40)` and produce exactly this:

```
Kaelen 40/40
takes 12 -> Kaelen 28/40
heals 30 -> Kaelen 40/40
takes 55 -> Kaelen 0/40
alive: no
heals 10 -> Kaelen 10/40
alive: yes
```

Notice `heals 30` only restores 12 of it, and `takes 55` stops at 0. The
main function never says so - the Hero enforces it, every time, without
being asked.
