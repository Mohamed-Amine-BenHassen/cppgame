#include "dungeon.h"

#include <iostream>

Dungeon::Dungeon() {
    rows_.push_back("####################");
    rows_.push_back("#@...#........#....#");
    rows_.push_back("#....#..####..#..!.#");
    rows_.push_back("#....#..#..#..#....#");
    rows_.push_back("#.####..#..#..####.#");
    rows_.push_back("#....#..#..#.......#");
    rows_.push_back("#.$..#..#.##..####.#");
    rows_.push_back("#....#........#..#.#");
    rows_.push_back("#.####.########..#.#");
    rows_.push_back("#......#k........#.#");
    rows_.push_back("#.####............>#");
    rows_.push_back("####################");

    // The map stores terrain only, so lift the player off it.
    for (int y = 0; y < height(); ++y) {
        for (int x = 0; x < width(); ++x) {
            if (rows_[y][x] == '@') {
                startX_ = x;
                startY_ = y;
                rows_[y][x] = '.';
            }
        }
    }
}

int Dungeon::width() const {
    return (int)rows_[0].size();
}

int Dungeon::height() const {
    return (int)rows_.size();
}

char Dungeon::tileAt(int x, int y) const {
    if (x < 0 || y < 0 || x >= width() || y >= height()) {
        return '#';                 // outside the map is solid rock
    }
    return rows_[y][x];
}

void Dungeon::setTile(int x, int y, char c) {
    if (x < 0 || y < 0 || x >= width() || y >= height()) {
        return;
    }
    rows_[y][x] = c;
}

bool Dungeon::isWall(int x, int y) const {
    return tileAt(x, y) == '#';
}

void Dungeon::render(int playerX, int playerY) const {
    for (int y = 0; y < height(); ++y) {
        for (int x = 0; x < width(); ++x) {
            if (x == playerX && y == playerY) {
                std::cout << '@';   // drawn on top, never stored
            } else {
                std::cout << rows_[y][x];
            }
        }
        std::cout << "\n";
    }
}

int Dungeon::startX() const {
    return startX_;
}

int Dungeon::startY() const {
    return startY_;
}
