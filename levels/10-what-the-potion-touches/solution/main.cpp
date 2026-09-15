#include <iostream>
#include <string>

// by value: works on a copy, so the caller never sees a thing
void brokenHeal(int hp, int amount) {
    hp += amount;
}

void heal(int& hp, int maxHp, int amount) {
    hp += amount;
    if (hp > maxHp) {
        hp = maxHp;
    }
}

void wound(int& hp, int amount) {
    hp -= amount;
    if (hp < 0) {
        hp = 0;
    }
}

bool tryBuy(int& gold, int price) {
    if (gold >= price) {
        gold -= price;
        return true;
    }
    return false;
}

int main() {
    int hp = 20;
    const int maxHp = 60;
    int gold = 30;

    std::cout << "hp " << hp << "\n";

    brokenHeal(hp, 30);
    std::cout << "brokenHeal 30 -> hp " << hp << "\n";

    heal(hp, maxHp, 30);
    std::cout << "heal 30 -> hp " << hp << "\n";

    heal(hp, maxHp, 30);
    std::cout << "heal 30 -> hp " << hp << "\n";

    wound(hp, 80);
    std::cout << "wound 80 -> hp " << hp << "\n";

    std::cout << "gold " << gold << "\n";

    bool boughtRope = tryBuy(gold, 10);
    std::cout << "buy rope for 10 -> " << (boughtRope ? "yes" : "no")
              << ", gold " << gold << "\n";

    bool boughtSword = tryBuy(gold, 50);
    std::cout << "buy sword for 50 -> " << (boughtSword ? "yes" : "no")
              << ", gold " << gold << "\n";

    return 0;
}
