#pragma once

#include <string>

class Hero {
public:
    Hero(std::string name, int maxHp);

    void takeDamage(int amount);
    void heal(int amount);

    bool isAlive() const;
    std::string status() const;

private:
    std::string name_;
    int hp_;
    int maxHp_;
};
