#include "game.h"

#include <cstdlib>
#include <fstream>
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

int Game::slainMonsters() const {
    return (int)monsters_.size() - livingMonsters();
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
            std::cout << "your pack is full.\n";
        }
    } else if (here == 'k') {
        pack_.add("iron key");
        std::cout << "you pocket the iron key.\n";
        dungeon_.setTile(px_, py_, '.');
    }
}

void Game::checkExit() {
    if (dungeon_.tileAt(px_, py_) != '>') {
        return;
    }

    if (!pack_.has("iron key")) {
        std::cout << "the door is iron, and locked. something in here opens it.\n";
        return;
    }

    std::cout << "=====================================\n";
    std::cout << "  YOU CLIMB THE STAIR INTO DAYLIGHT\n";
    std::cout << "=====================================\n";
    std::cout << "gold: " << gold_ << "\n";
    std::cout << "steps: " << steps_ << "\n";
    std::cout << "monsters slain: " << slainMonsters() << "\n";

    running_ = false;
    won_ = true;
}

void Game::showPack() const {
    std::cout << "-- pack (" << pack_.size() << "/" << pack_.capacity() << ") --\n";
    std::cout << pack_.list() << "\n";
    std::cout << "gold: " << gold_ << "\n";
}

void Game::help() const {
    std::cout << "-- commands --\n";
    std::cout << "w a s d   move, or attack whatever you walk into\n";
    std::cout << "i         look in your pack\n";
    std::cout << "p         drink a potion\n";
    std::cout << "save      write dungeon.sav\n";
    std::cout << "load      read dungeon.sav\n";
    std::cout << "?         this list\n";
    std::cout << "q         give up\n";
}

void Game::drinkPotion() {
    if (!pack_.has("potion")) {
        std::cout << "you have no potions.\n";
        return;
    }

    pack_.drop("potion");
    hp_ += roll(8) + 8;
    if (hp_ > maxHp_) {
        hp_ = maxHp_;
    }
    std::cout << "you drink a potion (hp " << hp_ << "/" << maxHp_ << ")\n";

    monstersAct();
    if (running_) {
        draw();
    }
}

void Game::save() {
    std::ofstream out("dungeon.sav");
    if (!out) {
        std::cout << "could not write the save.\n";
        return;
    }

    out << px_ << " " << py_ << "\n";
    out << hp_ << " " << maxHp_ << "\n";
    out << gold_ << " " << steps_ << "\n";
    out << dungeon_.width() << " " << dungeon_.height() << "\n";

    // the terrain, because the loot that has been taken is gone from it
    for (int y = 0; y < dungeon_.height(); ++y) {
        for (int x = 0; x < dungeon_.width(); ++x) {
            out << dungeon_.tileAt(x, y);
        }
        out << "\n";
    }

    out << monsters_.size() << "\n";
    for (const auto& m : monsters_) {
        out << m->hp() << "\n";
    }

    out << pack_.items().size() << "\n";
    for (const std::string& item : pack_.items()) {
        out << item << "\n";
    }

    std::cout << "saved.\n";
}

void Game::load() {
    std::ifstream in("dungeon.sav");
    if (!in) {
        std::cout << "no save file found.\n";
        return;
    }

    int w = 0;
    int h = 0;
    in >> px_ >> py_;
    in >> hp_ >> maxHp_;
    in >> gold_ >> steps_;
    in >> w >> h;
    in.ignore(10000, '\n');          // the newline the last >> left behind

    for (int y = 0; y < h; ++y) {
        std::string row;
        std::getline(in, row);
        for (int x = 0; x < w && x < (int)row.size(); ++x) {
            dungeon_.setTile(x, y, row[x]);
        }
    }

    int monsterCount = 0;
    in >> monsterCount;
    for (int i = 0; i < monsterCount && i < (int)monsters_.size(); ++i) {
        int hp = 0;
        in >> hp;
        monsters_[i]->setHp(hp);
    }

    int itemCount = 0;
    in >> itemCount;
    in.ignore(10000, '\n');

    pack_ = Pack(6);                 // empty it, or loading twice doubles up
    for (int i = 0; i < itemCount; ++i) {
        std::string item;
        std::getline(in, item);
        pack_.add(item);
    }

    std::cout << "loaded.\n";
    draw();
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
        checkExit();
        if (!running_) {
            return;                  // the game ended on that square
        }
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
    std::cout << "w a s d to move, i pack, p potion, ? help, q leave\n";
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
        } else if (cmd == "save") {
            save();
        } else if (cmd == "load") {
            load();
        } else if (cmd == "?") {
            help();
        } else {
            std::cout << "you cannot do that.\n";
        }
    }

    std::cout << "steps taken: " << steps_ << "\n";
}
