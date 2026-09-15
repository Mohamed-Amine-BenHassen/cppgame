#include <iostream>
#include <fstream>
#include <string>
#include <vector>

int main() {
    // ---- part 1: write the save file -------------------------------
    std::string name = "Kaelen";
    int hp = 28;
    int maxHp = 40;
    int gold = 137;
    std::vector<std::string> items{"torch", "rope", "iron key"};

    {
        std::ofstream out("save.txt");
        out << name << "\n";
        out << hp << " " << maxHp << "\n";
        out << gold << "\n";
        out << items.size() << "\n";
        for (const std::string& it : items) {
            out << it << "\n";
        }
    }   // out closes itself here

    std::cout << "saved to save.txt\n";

    // ---- part 2: read it back --------------------------------------
    std::ifstream in("save.txt");
    if (!in) {
        std::cout << "save.txt: no save file found\n";
        return 1;
    }

    std::string loadedName;
    int loadedHp = 0;
    int loadedMax = 0;
    int loadedGold = 0;
    int count = 0;

    std::getline(in, loadedName);
    in >> loadedHp >> loadedMax;
    in >> loadedGold;
    in >> count;
    in.ignore(10000, '\n');            // drop the newline left by >>

    std::vector<std::string> loadedItems;
    for (int i = 0; i < count; ++i) {
        std::string item;
        std::getline(in, item);
        loadedItems.push_back(item);
    }

    std::cout << "-- loaded --\n";
    std::cout << loadedName << " " << loadedHp << "/" << loadedMax << "\n";
    std::cout << "gold: " << loadedGold << "\n";
    std::cout << "items: " << loadedItems.size() << "\n";
    for (const std::string& it : loadedItems) {
        std::cout << "  " << it << "\n";
    }

    // ---- part 3: a file that is not there --------------------------
    std::ifstream missing("missing.txt");
    if (!missing) {
        std::cout << "missing.txt: no save file found\n";
    }

    return 0;
}
