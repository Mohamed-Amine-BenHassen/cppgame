#include <iostream>
#include <string>

int main() {
    std::string name = "Kaelen";
    char rank = 'R';

    int health = 120;
    health -= 20;              // the trap

    int gold = 25;
    gold += 17;                // found in the rubble

    int strength = 5;
    int attack = strength * 2 + 3;

    double crit = 0.15;
    bool alive = true;

    std::cout << "-- CHARACTER SHEET --\n";
    std::cout << "name: " << name << "\n";
    std::cout << "class: " << rank << "\n";
    std::cout << "health: " << health << "\n";
    std::cout << "gold: " << gold << "\n";
    std::cout << "attack: " << attack << "\n";
    std::cout << "crit: " << crit << "\n";
    std::cout << "alive: " << alive << "\n";

    return 0;
}