#pragma once

#include <string>

class Monster {
public:
    Monster(std::string name, char glyph, int hp, int attack, int x, int y);
    virtual ~Monster() = default;

    virtual std::string cry() const;        // "..."
    virtual int damageRoll() const;         // roll(attack_)

    void takeDamage(int amount);            // never below 0
    bool isAlive() const;

    const std::string& name() const;
    char glyph() const;
    int hp() const;
    int x() const;
    int y() const;

    void setHp(int hp);                     // used when loading a save

protected:
    std::string name_;
    char glyph_;
    int hp_;
    int attack_;
    int x_;
    int y_;
};

class Goblin : public Monster {
public:
    Goblin(int x, int y);                   // "goblin", 'g', 12 hp, attack 3
    std::string cry() const override;       // "yip!"
};

class Ogre : public Monster {
public:
    Ogre(int x, int y);                     // "ogre", 'O', 30 hp, attack 6
    std::string cry() const override;       // "GRAAA"
    int damageRoll() const override;        // roll(6) + 3
};
