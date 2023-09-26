# Tetris

Everyone loves Tetris.  It was very challenging detecting and reacting to collisions before blocks
pass through walls.  I learned a lot about SceneKit with this project.  I created this before I
knew much about SpriteKit.  Maybe I'll try a SpriteKit version in the future.

Gestures:
- Tap piece to rotate 90 degrees
- Swipe left or right to move sideways
- Swipe down slowly drop slowly
- Swipe down fast to drop fast

![Tetris](https://github.com/InvaderZim62/Tetris/assets/34785252/15b4d110-c1a1-4c87-b9a6-ce3be0e59072)

## Shape Movement Logic

The scene rederer handles movement of the shapes.  At a fixed interval (frameTime), the rederer
moves the falling shape down the screen one position at a time.  In between the fixed intervals, the
renderer services requests from the getures to rotate or move the falling shape laterally.  Before
a movement is made, it is checked for potential contacts with other shapes or the walls.

### Rotation contacts

Determine where each block would be, if rotated 90 deg.  Perform a hit test at that location, to see
if there is another block there.  If no contacts, make the 90 degree rotation.

### Translation contacts

Determine if any of the bumbers in the direction of requested motion are already in contact with
another block.  If no contacts, move one position in that direction.
