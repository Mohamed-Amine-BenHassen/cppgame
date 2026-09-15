#include <iostream>

int main() {
    int xp = 0;
    int level = 1;
    int session = 0;

    while (level < 5) {
        ++session;
        xp += 30;
        std::cout << "session " << session << ": +30 xp (total " << xp << ")\n";

        if (xp >= 100) {
            xp -= 100;              // the leftover carries over
            ++level;
            std::cout << "  ** level up ** now level " << level << " (xp " << xp << ")\n";
        }
    }

    std::cout << "training done: " << session << " sessions to reach level 5\n";

    return 0;
}
