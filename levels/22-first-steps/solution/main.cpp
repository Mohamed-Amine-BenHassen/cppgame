#include <iostream>
#include <string>

#include "dungeon.h"

int main() {
    Dungeon d;

    int px = d.startX();
    int py = d.startY();
    int steps = 0;

    std::cout << "-- THE DUNGEON OF THE NULL POINTER --\n";
    std::cout << "w a s d to move, q to leave\n";
    d.render(px, py);

    bool quit = false;
    std::string cmd;

    while (std::getline(std::cin, cmd)) {
        if (cmd == "q") {
            std::cout << "you climb back out.\n";
            quit = true;
            break;
        }

        int nx = px;
        int ny = py;
        std::string dir;

        if (cmd == "w")      { ny = py - 1; dir = "north"; }
        else if (cmd == "s") { ny = py + 1; dir = "south"; }
        else if (cmd == "a") { nx = px - 1; dir = "west";  }
        else if (cmd == "d") { nx = px + 1; dir = "east";  }
        else {
            std::cout << "you cannot do that.\n";
            continue;
        }

        // look before you leap: the hero is never inside a wall, ever
        if (d.isWall(nx, ny)) {
            std::cout << "a wall blocks you\n";
            continue;
        }

        px = nx;
        py = ny;
        ++steps;
        std::cout << "you step " << dir << "\n";
        d.render(px, py);
    }

    if (!quit) {
        std::cout << "the dungeon goes quiet.\n";
    }
    std::cout << "steps taken: " << steps << "\n";

    return 0;
}
