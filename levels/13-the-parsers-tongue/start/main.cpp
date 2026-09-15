#include <iostream>
#include <string>

int main() {
    std::string line;

    while (std::getline(std::cin, line)) {
        if (line == "quit") {
            break;
        }

        // TODO: split the line into verb and rest at the FIRST space.
        //       Remember std::string::npos for lines with no space at all.

        // TODO: respond, following the order in the brief:
        //       empty -> look -> go -> take -> catch-all
    }

    // TODO: print the farewell line, exactly once.

    return 0;
}
