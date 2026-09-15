#pragma once

#include <memory>
#include <vector>

#include "dungeon.h"
#include "monster.h"
#include "pack.h"

class Game {
public:
    Game();

    void run();

private:
    void draw() const;
    void step(int dx, int dy);
    void monstersAct();
    void pickUp();                          // react to the tile underfoot
    void drinkPotion();
    void showPack() const;
    Monster* monsterAt(int x, int y);
    int livingMonsters() const;

    Dungeon dungeon_;
    std::vector<std::unique_ptr<Monster>> monsters_;
    Pack pack_{6};

    int px_ = 0;
    int py_ = 0;
    int hp_ = 30;
    int maxHp_ = 30;
    int gold_ = 0;
    int steps_ = 0;
    bool running_ = true;
};
