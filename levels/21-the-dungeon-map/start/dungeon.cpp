#include "dungeon.h"

#include <iostream>

// TODO: Dungeon::Dungeon()
//   Fill rows_ with the map from the brief, one push_back per row.
//   Then scan every tile; when you find '@', record startX_/startY_
//   and overwrite that tile with '.'.

// TODO: int Dungeon::width() const     -> (int)rows_[0].size()
// TODO: int Dungeon::height() const    -> (int)rows_.size()

// TODO: char Dungeon::tileAt(int x, int y) const
//   Bounds check FIRST, return '#' when outside.

// TODO: void Dungeon::setTile(int x, int y, char c)
//   Silently do nothing when outside.

// TODO: bool Dungeon::isWall(int x, int y) const

// TODO: void Dungeon::render(int playerX, int playerY) const
//   For every row, for every column: print '@' if this is the player's
//   square, otherwise the terrain. Newline after each row.

// TODO: int Dungeon::startX() const
// TODO: int Dungeon::startY() const
