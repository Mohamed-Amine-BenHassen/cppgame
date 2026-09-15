#include <iostream>
#include <string>
#include <vector>

unsigned int rngState = 20260908u;

int roll(int sides) {
    rngState = rngState * 1103515245u + 12345u;
    return (int)((rngState >> 16) % (unsigned int)sides) + 1;
}

// TODO: class Monster  - name_, hp_ (protected)
//       constructor with an initialiser list, virtual destructor,
//       virtual cry() const  -> "..."
//       virtual attackRoll() const -> roll(4)
//       takeDamage, isAlive, name, hp

// TODO: class Goblin : public Monster   "goblin" 12  "yip!"       roll(4) + 1
// TODO: class Ogre   : public Monster   "ogre"   30  "GRAAA"      roll(6) + 3
// TODO: class Wraith : public Monster   "wraith"  8  "(silence)"  -- no override

int main() {
    std::vector<Monster*> horde;

    // TODO: new one of each, in order: Goblin, Ogre, Wraith

    // TODO: the four sections from the brief.

    // TODO: delete every monster in the horde.

    return 0;
}
