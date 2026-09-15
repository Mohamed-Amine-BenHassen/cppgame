#include <iostream>
#include <memory>
#include <string>
#include <utility>
#include <vector>

// Owns nothing but a promise: whatever happens, the destructor runs.
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

class Monster {
public:
    Monster(std::string name, int hp) : name_(name), hp_(hp) {}

    virtual ~Monster() {
        std::cout << "  " << name_ << " dissolves\n";
    }

    virtual std::string cry() const { return "..."; }

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
};

class Ogre : public Monster {
public:
    Ogre() : Monster("ogre", 30) {}
    std::string cry() const override { return "GRAAA"; }
};

class Wraith : public Monster {
public:
    Wraith() : Monster("wraith", 8) {}
    std::string cry() const override { return "(silence)"; }
};

int main() {
    Torch torch("hall");                 // lit first, so it goes out last

    std::vector<std::unique_ptr<Monster>> horde;
    horde.push_back(std::make_unique<Goblin>());
    horde.push_back(std::make_unique<Ogre>());
    horde.push_back(std::make_unique<Wraith>());

    std::cout << "-- the horde --\n";
    for (const auto& m : horde) {
        std::cout << m->name() << ": " << m->cry() << "\n";
    }

    std::cout << "-- you answer --\n";
    for (auto& m : horde) {
        m->takeDamage(15);
        std::cout << m->name() << " takes 15 (hp " << m->hp() << ")\n";
    }

    std::cout << "-- the dead are cleared --\n";

    std::vector<std::unique_ptr<Monster>> survivors;
    for (auto& m : horde) {
        if (m->isAlive()) {
            survivors.push_back(std::move(m));   // ownership changes hands
        }
    }
    for (auto& m : horde) {
        m.reset();          // the moved-from ones are empty; the dead dissolve here
    }

    std::cout << "survivors: " << survivors.size() << "\n";
    std::cout << "-- you leave --\n";

    // Nothing below this line. survivors dies, then horde, then torch.
    return 0;
}
