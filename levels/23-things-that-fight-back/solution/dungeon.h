#pragma once

#include <string>
#include <vector>

// The terrain of the dungeon. It knows nothing about the player, monsters
// or loot - only what the ground is made of, and how to draw itself.
class Dungeon {
public:
    Dungeon();                              // builds the fixed map

    int width() const;
    int height() const;

    char tileAt(int x, int y) const;        // '#' for anything outside the map
    void setTile(int x, int y, char c);     // ignores anything outside the map
    bool isWall(int x, int y) const;

    void render(int playerX, int playerY) const;

    int startX() const;
    int startY() const;

private:
    std::vector<std::string> rows_;
    int startX_ = 0;
    int startY_ = 0;
};
