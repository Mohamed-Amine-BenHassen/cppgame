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

    // TODO: open save.txt with std::ofstream and write, in order:
    //         name, then "hp maxHp", then gold, then the item COUNT,
    //         then one item per line.
    // TODO: print "saved to save.txt"

    // ---- part 2: read it back --------------------------------------
    // TODO: open save.txt with std::ifstream (check it opened!)
    //       read into FRESH variables and print the -- loaded -- block.
    //       Remember in.ignore(10000, '\n') after reading the count with >>,
    //       because "iron key" needs getline.

    // ---- part 3: a file that is not there --------------------------
    // TODO: try to open missing.txt, check it, print the failure line.

    return 0;
}
