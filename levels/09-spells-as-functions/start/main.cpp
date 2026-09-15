#include <iostream>
#include <string>

unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}

// TODO: int attackDamage(int strength)   -> roll(6) + strength / 2

// TODO: bool isDead(int hp)              -> true when hp <= 0

// TODO: void showBar(const std::string& name, int hp, int maxHp)
//       prints e.g.  ogre [######....] 18/30
//       ten cells, '#' for filled, '.' for empty, filled = hp * 10 / maxHp,
//       and never a negative number of cells.

int main() {
    int ogreHp = 30;
    const int ogreMax = 30;
    const int strength = 6;

    // TODO: the header, the first bar, three rounds, then the verdict.

    return 0;
}
