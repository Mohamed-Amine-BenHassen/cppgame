#include <iostream>
#include <string>

#include "dungeon.h"

int main() {
    Dungeon d;

    int px = d.startX();
    int py = d.startY();
    int steps = 0;

    // TODO: print the two header lines, then render the map.

    std::string cmd;
    // TODO: while (std::getline(std::cin, cmd)) { ... }
    //
    //   work out nx, ny from the command
    //   q          -> "you climb back out." and break
    //   w a s d    -> wall?  "a wall blocks you"
    //                 else   move, "you step <dir>", render
    //   otherwise  -> "you cannot do that."
    //
    //   If the loop ends because input ran out, print
    //   "the dungeon goes quiet." (but not after a q).

    // TODO: print "steps taken: <steps>"

    return 0;
}
