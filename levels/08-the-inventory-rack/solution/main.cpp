#include <iostream>
#include <string>
#include <vector>

int main() {
    std::vector<std::string> pack;
    std::string line;

    while (std::getline(std::cin, line)) {
        if (line == "done") {
            break;
        }
        pack.push_back(line);
    }

    if (pack.empty()) {
        std::cout << "your pack is empty\n";
        return 0;                       // nothing below is safe on an empty pack
    }

    std::cout << "-- PACK (" << pack.size() << " items) --\n";

    for (size_t i = 0; i < pack.size(); ++i) {
        std::cout << "  " << i + 1 << ". " << pack[i] << "\n";
    }

    bool hasTorch = false;
    for (const std::string& item : pack) {
        if (item == "torch") {
            hasTorch = true;
        }
    }

    std::cout << "slots used: " << pack.size() << " of 8\n";
    std::cout << "torch: " << (hasTorch ? "yes" : "no") << "\n";
    std::cout << "last picked up: " << pack.back() << "\n";

    return 0;
}
