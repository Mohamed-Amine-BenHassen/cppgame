#include <iostream>
#include <map>
#include <string>

int main() {
    std::map<std::string, int> hoard;
    std::string line;

    while (std::getline(std::cin, line)) {
        if (line == "done") {
            break;
        }
        if (line.empty()) {
            continue;
        }
        hoard[line]++;              // a missing key is born as 0, then becomes 1
    }

    if (hoard.empty()) {
        std::cout << "the hoard is empty\n";
        return 0;
    }

    std::cout << "-- hoard --\n";
    int total = 0;
    for (const auto& [name, count] : hoard) {
        std::cout << "  " << name << " x" << count << "\n";
        total += count;
    }

    std::cout << "distinct: " << hoard.size() << "\n";
    std::cout << "total: " << total << "\n";

    // find, not [] - asking must not create
    auto rat = hoard.find("rat");
    std::cout << "rat: ";
    if (rat == hoard.end()) {
        std::cout << "none\n";
    } else {
        std::cout << rat->second << "\n";
    }

    auto coin = hoard.find("gold coin");
    std::cout << "gold coin: ";
    if (coin == hoard.end()) {
        std::cout << "none\n";
    } else {
        std::cout << coin->second << "\n";
    }

    return 0;
}
