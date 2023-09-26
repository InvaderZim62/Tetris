# Tetris

Everyone loves Tetris.  It was very challenging detecting and reacting to collisions before blocks
pass through walls.  I learned a lot about SceneKit with this project.  I created this before I
knew much about SpriteKit.  Maybe I'll try a SpriteKit version in the future.

Gestures:
- Tap piece to rotate 90 degrees
- Swipe left or right to move sideways
- Swipe down slowly to drop slowly
- Swipe down fast to drop fast

![Tetris](https://github.com/InvaderZim62/Tetris/assets/34785252/15b4d110-c1a1-4c87-b9a6-ce3be0e59072)

## Shape Movement Logic

The scene rederer handles movement of the shapes.  At a fixed interval (frameTime), the rederer
moves the falling shape down the screen one position at a time.  In between the fixed intervals, the
renderer services requests from the getures to rotate or move the falling shape laterally.  Before
a movement is made, it is checked for potential contacts with other shapes or the walls.

### Rotation contacts

Determine where each of the shape's child-blocks would be, if the shape were rotated 90 degrees.
Perform a hit test at those locations, to see if anything is there.  If no contacts found, make the
90 degree rotation.

### Translation contacts

Each of the shape's child-blocks include invisible bumpers (spheres) sticking out from their sides.
Determine if any of the bumpers in the direction of requested motion are already contacting anything.
If no contacts found, move one position in that direction.
