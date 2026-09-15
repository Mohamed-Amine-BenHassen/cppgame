#include <iostream>
#include <string>
#include <vector>

unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}

struct Monster {
    std::string name;
    int hp;
    int attack;
};

void describe(const Monster& m) {
    std::cout << m.name << "  hp " << m.hp << "  atk " << m.attack << "\n";
}

bool alive(const Monster& m) {
    return m.hp > 0;
}

void wound(Monster& m, int amount) {
    m.hp -= amount;
    if (m.hp < 0) {
        m.hp = 0;
    }
}

int main() {
    std::vector<Monster> room;

    // TODO: read "name hp attack" until the word "done", push_back each one.

    // TODO: if the room is empty, print the two empty-room lines and return 0.

    // TODO: header, describe them all, total threat, toughest.

    // TODO: the sweep - one roll(6) + 3 per monster, in order,
    //       printing the hit and, when it kills, the death line.

    // TODO: still standing.

    return 0;
}
