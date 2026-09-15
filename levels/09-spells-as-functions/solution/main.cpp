#include <iostream>
#include <string>

unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}

int attackDamage(int strength) {
    return roll(6) + strength / 2;
}

bool isDead(int hp) {
    return hp <= 0;
}

void showBar(const std::string& name, int hp, int maxHp) {
    int filled = hp * 10 / maxHp;
    if (filled < 0) {
        filled = 0;                 // a corpse is not owed negative cells
    }

    std::cout << name << " [";
    for (int i = 0; i < filled; ++i) {
        std::cout << '#';
    }
    for (int i = filled; i < 10; ++i) {
        std::cout << '.';
    }
    std::cout << "] " << hp << "/" << maxHp << "\n";
}

int main() {
    int ogreHp = 30;
    const int ogreMax = 30;
    const int strength = 6;

    std::cout << "-- the ogre blocks the stair --\n";
    showBar("ogre", ogreHp, ogreMax);

    for (int round = 1; round <= 3; ++round) {
        int d = attackDamage(strength);
        ogreHp -= d;
        std::cout << "round " << round << ": you deal " << d << "\n";
        showBar("ogre", ogreHp, ogreMax);
    }

    if (isDead(ogreHp)) {
        std::cout << "the ogre is down\n";
    } else {
        std::cout << "the ogre still stands\n";
    }

    return 0;
}
