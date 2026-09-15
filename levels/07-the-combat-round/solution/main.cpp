#include <iostream>

unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}

int main() {
    int heroHp = 30;
    int goblinHp = 22;
    int round = 0;

    while (heroHp > 0 && goblinHp > 0) {
        ++round;
        std::cout << "-- round " << round << " --\n";

        int mine = roll(6) + 2;
        goblinHp -= mine;
        std::cout << "you hit the goblin for " << mine
                  << " (goblin hp " << goblinHp << ")\n";

        if (goblinHp <= 0) {
            break;                 // a dead goblin does not get to swing
        }

        int theirs = roll(4) + 1;
        heroHp -= theirs;
        std::cout << "the goblin hits you for " << theirs
                  << " (your hp " << heroHp << ")\n";
    }

    if (heroHp > 0) {
        std::cout << "the goblin falls. you live, on " << heroHp << " hp.\n";
    } else {
        std::cout << "you fall. the dungeon keeps your gold.\n";
    }

    return 0;
}
