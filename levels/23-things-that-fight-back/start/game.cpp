#include "game.h"

#include <cstdlib>
#include <iostream>
#include <string>

#include "dice.h"

// TODO: Game::Game()
//   px_ = dungeon_.startX(); py_ = dungeon_.startY();
//   then make_unique a Goblin(4,5), a Goblin(9,9) and an Ogre(14,10),
//   pushed back in that order.

// TODO: Monster* Game::monsterAt(int x, int y)
//   the first LIVING monster on that square, via m.get(), else nullptr.

// TODO: int Game::livingMonsters() const

// TODO: void Game::draw() const
//   For each row: start from dungeon_.tileAt(x, y), draw living monsters
//   over it, then the hero over everything. Then the status line:
//     hp <hp_>/<maxHp_>   steps <steps_>   monsters alive <n>
//   (three spaces between the parts)

// TODO: void Game::step(int dx, int dy)
//   monster there -> attack for roll(6) + 2, no movement
//   wall          -> "a wall blocks you", turn does not happen
//   otherwise     -> move, ++steps_, "you step <dir>"
//   then monstersAct() and draw() - but only if the turn happened.

// TODO: void Game::monstersAct()
//   every living monster orthogonally adjacent hits for damageRoll().
//   At 0 hp: "you die in the dark." and running_ = false.

// TODO: void Game::run()
//   the two header lines, one draw(), then the input loop.
//   Finish with "steps taken: <steps_>".
