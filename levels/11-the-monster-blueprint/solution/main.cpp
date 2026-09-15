#include <iostream>
#include <string>

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
    Monster goblin{"goblin", 12, 3};
    Monster ogre{"ogre", 30, 7};

    std::cout << "-- the room --\n";
    describe(goblin);
    describe(ogre);

    std::cout << "you swing at the goblin for 9\n";
    wound(goblin, 9);
    describe(goblin);
    std::cout << "goblin alive: " << (alive(goblin) ? "yes" : "no") << "\n";

    std::cout << "you swing at the goblin for 9\n";
    wound(goblin, 9);
    describe(goblin);
    std::cout << "goblin alive: " << (alive(goblin) ? "yes" : "no") << "\n";

    std::cout << "the ogre turns to face you\n";
    describe(ogre);

    return 0;
}
