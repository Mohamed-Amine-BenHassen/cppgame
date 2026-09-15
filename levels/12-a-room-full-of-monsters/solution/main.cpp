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

    std::string name;
    while (std::cin >> name) {
        if (name == "done") {
            break;
        }
        Monster m;
        m.name = name;
        std::cin >> m.hp >> m.attack;
        room.push_back(m);
    }

    if (room.empty()) {
        std::cout << "-- ROOM (0 monsters) --\n";
        std::cout << "nothing here but dust\n";
        return 0;
    }

    std::cout << "-- ROOM (" << room.size() << " monsters) --\n";
    for (const Monster& m : room) {
        describe(m);
    }

    int threat = 0;
    for (const Monster& m : room) {
        threat += m.attack;
    }
    std::cout << "total threat: " << threat << "\n";

    // strictly greater, so a tie keeps the earlier monster
    size_t toughest = 0;
    for (size_t i = 1; i < room.size(); ++i) {
        if (room[i].hp > room[toughest].hp) {
            toughest = i;
        }
    }
    std::cout << "toughest: " << room[toughest].name << "\n";

    std::cout << "-- you sweep the room --\n";
    for (Monster& m : room) {              // a reference, or the damage is lost
        int d = roll(6) + 3;
        wound(m, d);
        std::cout << "you hit " << m.name << " for " << d
                  << " (hp " << m.hp << ")\n";
        if (alive(m) == false) {
            std::cout << "  " << m.name << " dies\n";
        }
    }

    int standing = 0;
    for (const Monster& m : room) {
        if (alive(m)) {
            ++standing;
        }
    }
    std::cout << "still standing: " << standing << "\n";

    return 0;
}
