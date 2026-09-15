#include <iostream>
#include <string>
#include <vector>

unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}

class Monster {
public:
    Monster(std::string name, int hp) : name_(name), hp_(hp) {}

    // virtual, because the horde is deleted through Monster*
    virtual ~Monster() = default;

    virtual std::string cry() const { return "..."; }
    virtual int attackRoll() const { return roll(4); }

    void takeDamage(int a) {
        hp_ -= a;
        if (hp_ < 0) {
            hp_ = 0;
        }
    }

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

class Ogre : public Monster {
public:
    Ogre() : Monster("ogre", 30) {}
    std::string cry() const override { return "GRAAA"; }
    int attackRoll() const override { return roll(6) + 3; }
};

class Wraith : public Monster {
public:
    Wraith() : Monster("wraith", 8) {}
    std::string cry() const override { return "(silence)"; }
    // no attackRoll here on purpose - it inherits roll(4)
};

int main() {
    std::vector<Monster*> horde;
    horde.push_back(new Goblin());
    horde.push_back(new Ogre());
    horde.push_back(new Wraith());

    std::cout << "-- the horde --\n";
    for (Monster* m : horde) {
        std::cout << m->name() << ": " << m->cry() << "\n";
    }

    std::cout << "-- they strike --\n";
    for (Monster* m : horde) {
        std::cout << m->name() << " strikes for " << m->attackRoll() << "\n";
    }

    std::cout << "-- you answer --\n";
    for (Monster* m : horde) {
        m->takeDamage(15);
        std::cout << m->name() << " takes 15 (hp " << m->hp() << ")\n";
        if (m->isAlive() == false) {
            std::cout << "  " << m->name() << " is gone\n";
        }
    }

    int survivors = 0;
    for (Monster* m : horde) {
        if (m->isAlive()) {
            ++survivors;
        }
    }
    std::cout << "survivors: " << survivors << "\n";

    for (Monster* m : horde) {
        delete m;                 // one delete for every new
    }

    return 0;
}
