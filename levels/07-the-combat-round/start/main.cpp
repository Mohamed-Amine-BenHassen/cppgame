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

    // TODO: while both are alive, fight a round:
    //         ++round, print the round header
    //         hero deals roll(6) + 2, print it and the goblin's remaining hp
    //         if the goblin is down, break BEFORE it gets to swing
    //         goblin deals roll(4) + 1, print it and your remaining hp

    // TODO: after the loop, print who won.

    return 0;
}
