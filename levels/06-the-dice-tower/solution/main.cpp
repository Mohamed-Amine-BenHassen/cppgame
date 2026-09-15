#include <iostream>

// ---- a gift from the tower: dice you can trust to lie the same way twice.
//      You will learn to write functions like this on floor 9.
unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}
// ----------------------------------------------------------------------

int main() {
    int hits = 0;
    int total = 0;

    for (int i = 1; i <= 10; ++i) {
        int r = roll(6);                  // once, and only once, per pass
        std::cout << "roll " << i << ": " << r << "\n";

        total += r;
        if (r >= 4) {
            ++hits;
        }
    }

    std::cout << "hits: " << hits << " of 10\n";
    std::cout << "damage: " << total << "\n";

    return 0;
}
