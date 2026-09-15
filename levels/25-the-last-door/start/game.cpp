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
                c = '@';
            }

            std::cout << c;
        }
        std::cout << "\n";
    }

    std::cout << "hp " << hp_ << "/" << maxHp_
              << "   gold " << gold_
              << "   steps " << steps_
              << "   monsters alive " << livingMonsters() << "\n";
}

void Game::pickUp() {
    char here = dungeon_.tileAt(px_, py_);

    if (here == '$') {
        int found = roll(20) + 10;
        gold_ += found;
        std::cout << "you scoop up " << found << " gold\n";
        dungeon_.setTile(px_, py_, '.');
    } else if (here == '!') {
        if (pack_.add("potion")) {
            std::cout << "you pocket a potion.\n";
            dungeon_.setTile(px_, py_, '.');
        } else {
            std::cout << "your pack is full.\n";   // it stays on the floor
        }
    } else if (here == 'k') {
        pack_.add("iron key");
        std::cout << "you pocket the iron key.\n";
        dungeon_.setTile(px_, py_, '.');
    }
}

void Game::showPack() const {
    std::cout << "-- pack (" << pack_.size() << "/" << pack_.capacity() << ") --\n";
    std::cout << pack_.list() << "\n";
    std::cout << "gold: " << gold_ << "\n";
}

void Game::drinkPotion() {
    if (!pack_.has("potion")) {
        std::cout << "you have no potions.\n";
        return;                                   // costs nothing
    }

    pack_.drop("potion");
    hp_ += roll(8) + 8;
    if (hp_ > maxHp_) {
        hp_ = maxHp_;
    }
    std::cout << "you drink a potion (hp " << hp_ << "/" << maxHp_ << ")\n";

    monstersAct();                                // drinking is a turn
    if (running_) {
        draw();
    }
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
        return;
    } else {
        px_ = nx;
        py_ = ny;
        ++steps_;

        std::string dir = "east";
        if (dy < 0)      { dir = "north"; }
        else if (dy > 0) { dir = "south"; }
        else if (dx < 0) { dir = "west";  }

        std::cout << "you step " << dir << "\n";
        pickUp();
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
            continue;
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
    std::cout << "w a s d to move, i for your pack, p to drink, q to leave\n";
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
        } else if (cmd == "i") {
            showPack();
        } else if (cmd == "p") {
            drinkPotion();
        } else {
            std::cout << "you cannot do that.\n";
        }
    }

    std::cout << "steps taken: " << steps_ << "\n";
}

// ---------------------------------------------------------------------
// FLOOR 25 - the last additions. Everything above still stands.
//
// 1. void Game::checkExit()
//      called from step(), right after pickUp().
//      not on '>'            -> nothing
//      on '>' without the key-> "the door is iron, and locked. something in here opens it."
//      on '>' with the key   -> the victory block, running_ = false, won_ = true
//
// 2. int Game::slainMonsters() const   -> monsters_.size() - livingMonsters()
//
// 3. void Game::save()   writes dungeon.sav in the exact order in the brief
// 4. void Game::load()   reads it back, prints "loaded." and draws.
//                        Missing file -> "no save file found." and no changes.
// 5. void Game::help() const
//
// 6. run(): wire up save / load / ? as FREE actions, and update the
//    header line to
//      w a s d to move, i pack, p potion, ? help, q leave
// ---------------------------------------------------------------------
