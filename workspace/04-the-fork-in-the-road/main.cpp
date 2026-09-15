#include <iostream>

int main() {
    int hp = 0;
    int potions = 0;
    int hasKey = 0;

    std::cin >> hp >> potions >> hasKey;

    // TODO 1: print the status line.
    //         under 30 -> critical, under 70 -> wounded, else healthy
 // what shape is the hero in?
        if (hp < 30) {
            std::cout << "status: critical\n";
        } else if (hp < 70) {
            std::cout << "status: wounded\n";
        } else {
            std::cout << "status: healthy\n";
        }

        // what do they do about it?
        if (hp <= 0) {
            std::cout << "You are dead. The dungeon keeps your gold.\n";
        } else if (hp < 30 && potions > 0) {
            std::cout << "You drink a potion. Health back to 100.\n";

        } else if (hp < 30) {
            std::cout << "You crawl toward the stairs, bleeding.\n";
        } else if (hasKey) {
            std::cout << "You unlock the iron door and descend.\n";
        } else {
            std::cout << "You search the room for a key.\n";
        }

        return 0;
    }
