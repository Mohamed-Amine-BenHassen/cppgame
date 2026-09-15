#include "game.h"

#include <cstdlib>
#include <iostream>
#include <string>

#include "dice.h"

Game::Game() {
    px_ = dungeon_.startX();
    py_ = dungeon_.startY();

    monsters_.push_back(std::make_unique<Goblin>(4, 5));
    monsters_.push_back(std::make_unique<Goblin>(9, 9));
    monsters_.push_back(std::make_unique<Ogre>(14, 10));
}

// Borrowed, not owned: the vector keeps ownership, the caller just looks.
Monster* Game::monsterAt(int x, int y) {
    for (auto& m : monsters_) {
        if (m->isAlive() && m->x() == x && m->y() == y) {
            return m.get();
        }
    }
    return nullptr;
}

int Game::livingMonsters() const {
    int n = 0;
    for (const auto& m : monsters_) {
        if (m->isAlive()) {
            ++n;
        }
    }
    return n;
}

void Game::draw() const {
    for (int y = 0; y < dungeon_.height(); ++y) {
        for (int x = 0; x < dungeon_.width(); ++x) {
            char c = dungeon_.tileAt(x, y);

            for (const auto& m : monsters_) {
                if (m->isAlive() && m->x() == x && m->y() == y) {
                    c = m->glyph();
                }
            }

            if (x == px_ && y == py_) {
                c = '@';                    // the hero is always on top
            }

            std::cout << c;
        }
        std::cout << "\n";
    }

    std::cout << "hp " << hp_ << "/" << maxHp_
              << "   steps " << steps_
              << "   monsters alive " << livingMonsters() << "\n";
}

void Game::step(int dx, int dy) {
    int nx = px_ + dx;
    int ny = py_ + dy;

    Monster* target = monsterAt(nx, ny);

    if (target != nullptr) {
        int d = roll(6) + 2;
        target->takeDamage(d);
        std::cout << "you hit the " << target->name() << " for " << d
                  << " (" << target->name() << " hp " << target->hp() << ")\n";
        if (!target->isAlive()) {
            std::cout << "the " << target->name() << " dies\n";
        }
    } else if (dungeon_.isWall(nx, ny)) {
        std::cout << "a wall blocks you\n";
        return;                             // no turn happened at all
    } else {
        px_ = nx;
        py_ = ny;
        ++steps_;

        std::string dir = "east";
        if (dy < 0)      { dir = "north"; }
        else if (dy > 0) { dir = "south"; }
        else if (dx < 0) { dir = "west";  }

        std::cout << "you step " << dir << "\n";
    }

    monstersAct();
    if (running_) {
        draw();
    }
}

void Game::monstersAct() {
    for (auto& m : monsters_) {
        if (!m->isAlive()) {
            continue;
        }
        int dist = std::abs(m->x() - px_) + std::abs(m->y() - py_);
        if (dist != 1) {
            continue;                       // orthogonally adjacent only
        }

        int d = m->damageRoll();
        hp_ -= d;
        if (hp_ < 0) {
            hp_ = 0;
        }
        std::cout << "the " << m->name() << " hits you for " << d
                  << " (hp " << hp_ << ")\n";

        if (hp_ <= 0) {
            std::cout << "you die in the dark.\n";
            running_ = false;
            return;
        }
    }
}

void Game::run() {
    std::cout << "-- THE DUNGEON OF THE NULL POINTER --\n";
    std::cout << "w a s d to move, q to leave\n";
    draw();

    std::string cmd;
    while (running_ && std::getline(std::cin, cmd)) {
        if (cmd == "q") {
            std::cout << "you climb back out.\n";
            break;
        } else if (cmd == "w") {
            step(0, -1);
        } else if (cmd == "s") {
            step(0, 1);
        } else if (cmd == "a") {
            step(-1, 0);
        } else if (cmd == "d") {
            step(1, 0);
        } else {
            std::cout << "you cannot do that.\n";
        }
    }

    std::cout << "steps taken: " << steps_ << "\n";
}

// ---------------------------------------------------------------------
// FLOOR 24 - what to add. Your floor 23 code above still works; extend it.
//
// 1. draw(): add gold to the status line ->
//      hp 30/30   gold 0   steps 0   monsters alive 3
//
// 2. void Game::pickUp()
//      Look at dungeon_.tileAt(px_, py_) and react:
//        '$'  gold_ += roll(20) + 10;  "you scoop up <n> gold";  clear tile
//        '!'  pack_.add("potion")  ->  "you pocket a potion." + clear tile
//                                 or  "your pack is full."  (leave it there)
//        'k'  pack_.add("iron key");   "you pocket the iron key.";  clear tile
//      Clear a tile with dungeon_.setTile(px_, py_, '.').
//
// 3. step(): call pickUp() right after a successful move,
//    before monstersAct().
//
// 4. void Game::showPack() const
//      -- pack (<size>/<capacity>) --
//      <pack_.list()>
//      gold: <gold_>
//
// 5. void Game::drinkPotion()
//      no potion -> "you have no potions." and NO turn
//      otherwise -> drop it, heal roll(8) + 8 (capped at maxHp_),
//                   "you drink a potion (hp <hp_>/<maxHp_>)",
//                   then monstersAct() and draw() - it costs a turn.
//
// 6. run(): wire up 'i' -> showPack()  (free, no turn)
//                   'p' -> drinkPotion()
// ---------------------------------------------------------------------
