#include <iostream>
#include <string>

int main() {
    std::string line;

    while (std::getline(std::cin, line)) {
        if (line == "quit") {
            break;
        }

        if (line.empty()) {
            std::cout << "say something.\n";
            continue;
        }

        std::string verb;
        std::string rest;

        size_t space = line.find(' ');
        if (space == std::string::npos) {
            verb = line;                    // no space: it is all verb
        } else {
            verb = line.substr(0, space);
            rest = line.substr(space + 1);
        }

        if (verb == "look") {
            std::cout << "the room is dark.\n";
        } else if (verb == "go" && !rest.empty()) {
            std::cout << "you walk " << rest << ".\n";
        } else if (verb == "take" && !rest.empty()) {
            std::cout << "you pocket the " << rest << ".\n";
        } else if (verb == "go" || verb == "take") {
            std::cout << verb << " what?\n";
        } else {
            std::cout << "you cannot " << verb << ".\n";
        }
    }

    std::cout << "you leave the room.\n";

    return 0;
}
