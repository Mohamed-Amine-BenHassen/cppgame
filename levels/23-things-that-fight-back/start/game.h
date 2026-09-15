#pragma once

#include <memory>
#include <vector>

#include "dungeon.h"
#include "monster.h"

class Game {
public:
    Game();

    void run();                             // the whole game loop

private:
    void draw() const;                      // map, monsters, hero, status
    void step(int dx, int dy);              // move, or attack what is there
    void monstersAct();                     // everything adjacent hits back
    Monster* monsterAt(int x, int y);       // nullptr when the square is clear
    int livingMonsters() const;

    Dungeon dungeon_;
    std::vector<std::unique_ptr<Monster>> monsters_;

    int px_ = 0;
    int py_ = 0;
    int hp_ = 30;
    int maxHp_ = 30;
    int steps_ = 0;
    bool running_ = true;
};
