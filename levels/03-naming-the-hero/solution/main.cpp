#include <iostream>
#include <string>

int main() {
    std::string name;
    int level = 0;

    std::cout << "What shall we call you?\n";
    std::getline(std::cin, name);

    std::cout << "How many floors have you climbed?\n";
    std::cin >> level;

    std::cout << "\n";
    std::cout << name << ", level " << level << "\n";
    std::cout << "max health: " << 80 + level * 20 << "\n";
    std::cout << "next level at: " << level * 100 << " xp\n";

    return 0;
}
