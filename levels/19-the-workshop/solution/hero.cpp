#include "hero.h"

Hero::Hero(std::string name, int maxHp) {
    name_ = name;
    maxHp_ = maxHp;
    hp_ = maxHp;
}

void Hero::takeDamage(int amount) {
    hp_ -= amount;
    if (hp_ < 0) {
        hp_ = 0;
    }
}

void Hero::heal(int amount) {
    hp_ += amount;
    if (hp_ > maxHp_) {
        hp_ = maxHp_;
    }
}

// const in the header AND here, or it is a different function
bool Hero::isAlive() const {
    return hp_ > 0;
}

std::string Hero::status() const {
    return name_ + " " + std::to_string(hp_) + "/" + std::to_string(maxHp_);
}
