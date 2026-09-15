#include "monster.h"

#include "dice.h"

Monster::Monster(std::string name, char glyph, int hp, int attack, int x, int y)
    : name_(name), glyph_(glyph), hp_(hp), attack_(attack), x_(x), y_(y) {}

std::string Monster::cry() const {
    return "...";
}

int Monster::damageRoll() const {
    return roll(attack_);
}

void Monster::takeDamage(int amount) {
    hp_ -= amount;
    if (hp_ < 0) {
        hp_ = 0;
    }
}

bool Monster::isAlive() const {
    return hp_ > 0;
}

const std::string& Monster::name() const { return name_; }
char Monster::glyph() const              { return glyph_; }
int Monster::hp() const                  { return hp_; }
int Monster::x() const                   { return x_; }
int Monster::y() const                   { return y_; }

Goblin::Goblin(int x, int y) : Monster("goblin", 'g', 12, 3, x, y) {}

std::string Goblin::cry() const {
    return "yip!";
}

Ogre::Ogre(int x, int y) : Monster("ogre", 'O', 30, 6, x, y) {}

std::string Ogre::cry() const {
    return "GRAAA";
}

int Ogre::damageRoll() const {
    return roll(6) + 3;
}
