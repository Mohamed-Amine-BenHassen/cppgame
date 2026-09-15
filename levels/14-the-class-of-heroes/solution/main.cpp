#include <iostream>
#include <string>

class Hero {
public:
    Hero(std::string name, int maxHp) {
        name_ = name;
        maxHp_ = maxHp;
        hp_ = maxHp;
    }

    void takeDamage(int amount) {
        hp_ -= amount;
        if (hp_ < 0) {
            hp_ = 0;
        }
    }

    void heal(int amount) {
        hp_ += amount;
        if (hp_ > maxHp_) {
            hp_ = maxHp_;
        }
    }

    bool isAlive() const {
        return hp_ > 0;
    }

    std::string status() const {
        return name_ + " " + std::to_string(hp_) + "/" + std::to_string(maxHp_);
    }

private:
    std::string name_;
    int hp_;
    int maxHp_;
};

int main() {
    Hero kaelen("Kaelen", 40);

    std::cout << kaelen.status() << "\n";

    kaelen.takeDamage(12);
    std::cout << "takes 12 -> " << kaelen.status() << "\n";

    kaelen.heal(30);
    std::cout << "heals 30 -> " << kaelen.status() << "\n";

    kaelen.takeDamage(55);
    std::cout << "takes 55 -> " << kaelen.status() << "\n";
    std::cout << "alive: " << (kaelen.isAlive() ? "yes" : "no") << "\n";

    kaelen.heal(10);
    std::cout << "heals 10 -> " << kaelen.status() << "\n";
    std::cout << "alive: " << (kaelen.isAlive() ? "yes" : "no") << "\n";

    return 0;
}
