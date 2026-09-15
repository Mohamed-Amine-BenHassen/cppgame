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

    // TODO: a for loop from 1 to 10.
    //       Each pass: roll(6) ONCE into a variable,
    //                  print "roll <n>: <value>",
    //                  add it to total,
    //                  and count it as a hit if it is 4 or more.

    // TODO: print the two summary lines.

    return 0;
}
