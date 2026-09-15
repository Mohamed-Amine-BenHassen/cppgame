// Do not change this file. Make dungeon.cpp satisfy it.
#include <iostream>

#include "dungeon.h"

int main() {
    Dungeon d;

    std::cout << "-- THE DUNGEON OF THE NULL POINTER --\n";
    std::cout << "size: " << d.width() << "x" << d.height() << "\n";
    std::cout << "start: " << d.startX() << "," << d.startY() << "\n";

    d.render(d.startX(), d.startY());

    std::cout << "tile 0,0 is " << d.tileAt(0, 0) << "\n";
    std::cout << "tile 2,6 is " << d.tileAt(2, 6) << "\n";
    std::cout << "tile 8,9 is " << d.tileAt(8, 9) << "\n";
    std::cout << "tile -1,-1 is " << d.tileAt(-1, -1) << "\n";
    std::cout << "tile 999,999 is " << d.tileAt(999, 999) << "\n";
    std::cout << "wall at 1,1: " << (d.isWall(1, 1) ? "yes" : "no") << "\n";
    std::cout << "wall at 0,1: " << (d.isWall(0, 1) ? "yes" : "no") << "\n";

    std::cout << "-- the hero stands on the gold --\n";
    d.render(2, 6);

    return 0;
}
