// Do not change this file. Make hero.h and hero.cpp satisfy it.
#include <iostream>

#include "dice.h"
#include "hero.h"

int main() {
    Hero kaelen("Kaelen", 40);

    std::cout << "-- the workshop --\n";
    std::cout << kaelen.status() << "\n";

    for (int round = 1; round <= 3; ++round) {
        int d = roll(6) + 2;
        kaelen.takeDamage(d);
        std::cout << "round " << round << ": takes " << d
                  << " -> " << kaelen.status() << "\n";
    }

    kaelen.heal(12);
    std::cout << "a potion -> " << kaelen.status() << "\n";
    std::cout << "alive: " << (kaelen.isAlive() ? "yes" : "no") << "\n";

    return 0;
}
