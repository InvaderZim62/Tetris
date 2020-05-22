//
//  TetrisViewController.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  Note: calls to contactTest (or functions that call contactTest) must be made from the renderer loop.
//  Ealier versions of the app called contactTest from a sepatate simulation loop, and from the pan gesture.
//  This resulted in contactTest returning no contacts, when there have been, resulting in shapes moving
//  through other blocks.
//
//  Note: handlePan stopped getting called during softDrop, because moveShapeDown was starving the background
//  tasks.  This prevented pan state = .ended from being called, to stop the softDrop when the user stops
//  panning.  To get around this, I reset frameTime to the normal (non-softDrop) value, if moveShapeDown is
//  called twice, without a call to handlePan (see isPanHandled).
//
//  Usefull SCeneKit conversions...
//
//    convertPosition   Convert position of node in one reference to another reference
//
//                      ex.  let blockNodeRootPosition = fallingShape.convertPosition(blockNode.position, to: boardScene.rootNode)
//                           blockNode is a child of fallingShape, which is a child of boardScene.rootNode
//
//    projectPoint      Convert scene coordinates to screen coordinates
//
//                      ex.  let screenPosition = scnView.projectPoint(fallingShape.position)
//                           fallingShape.position = SCNVector3(0.5, 4.5, 0.0)  // scene coordinates
//                           screenPosition = SCNVectors(200.6, 215.3, 0.96)    // screen coordinates
//
//                      Note: convert grandchild position to child position, before projecting to screen position
//
//                      ex.  let blockNodeRootPosition = fallingShape.convertPosition(blockNode.position, to: boardScene.rootNode)
//                           let screenPosition = scnView.projectPoint(blockNodeRootPosition)
//
//    unprojectPoint    Convert screen coordinates to scene coordinates
//
//                      ex.  let scenePosition = scnView.unprojectPoint(screenPosition)
//
//    hitTest           Return nodes at screen point, if any
//
//                      ex.  let hitResults = scnView.hitTest(location, options: nil)  // returns closest node
//                      -or- let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])  // returns all nodes
//                           location = GCPoint(200.6, 215.3)  // screen coordinates
//                           hitResults = [SCNHitTestResult]   // hitResult[0].node
//
//    contactTest       Return nodes contacting input node
//
//                      ex.  boardScene.physicsWorld.updateCollisionPairs()  // force physics engine to re-evalute possible contacts (may not be needed?)
//                           let contactedNodes = boardScene.physicsWorld.contactTest(with: inputNode.physicsBody!, options: nil)
//                           inputNode is a node at any level within the scene
//                           contactedNodes = [SCNPhysicsContact]  // contactedNodes[0].nodeA & .nodeB (one being the inputNode)
//

import UIKit
import QuartzCore
import SceneKit

enum ScreenSide: Int {
    case left
    case right
    case top
    case bottom
}

struct Constants {
    static let blockSpacing: CGFloat = 1
    static let blockSize: CGFloat = 0.97 * Constants.blockSpacing  // slightly smaller, to prevent continuous contact detection
    static let backgroundThickness: CGFloat = 0.1
    static let blockThickness: CGFloat = 0.5
    static let cameraDistance: CGFloat = 23 * Constants.blockSpacing
    static let blocksPerBase = 12        // frame dimension
    static let blocksPerSide = 22        // frame dimension
    static let defaultScore = 1000      // default high score for top 10 list (must beat to get on list)
    static let softDropTimeFrame = 0.05  // seconds
    static let hardDropTimeFrame = 0.005 // seconds
    static let hardDropPanSpeedThreshold: CGFloat = 20.0  // y-speed to start hard drop
    static let panSpeedSoftDropDeadband: CGFloat = 5.0
    static let panSpeedLateralDeadband: CGFloat = 8.0
}

class TetrisViewController: UIViewController {
    
    enum MotionState {
        case idle
        case lateralPan
        case softDrop
        case hardDrop
    }
    
    var scnView: SCNView!
    var cameraNode: SCNNode!

    let boardScene = BoardScene()
    var hud = Hud()

    var highScores = [Int]()
    var highScoreInitials = [String]()
    var tapGesture = UITapGestureRecognizer()
    var panGesture = UIPanGestureRecognizer()
    var shapeScreenStartLocation: SCNVector3!
    var targetPositionX: Float = 0.0
    var isPanHandled = false
    var fallingShape: ShapeNode!
    var isShapeFalling = false
    var motionState: MotionState!
    var isRotationRequested = false
    var spawnTime: TimeInterval = 0
    var frameTime: Double!  // instantaneous from time, affects speed of shapes falling
    var levelFrameTime = 1.0  // frame time when not hard drop or soft drop (reduces as game level increases)
    var level = 0
    var levelRowsCleared = 0
    //                rows:  1    2    3     4
    let rowRemovalPoints = [40, 100, 300, 1200]
    //                level:  0   1   2   3   4   5   6   7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29+
    let framesPerGridcell = [48, 43, 38, 33, 28, 23, 18, 13, 8, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1]
    let framesPerSecond = 60.0988  // Nintendo NES

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Start of code

    override func viewDidLoad() {
        super.viewDidLoad()
        boardScene.setup()
        setupView()  // scnView.scene = boardScene
        setupCamera()
        setupLight()
        setupHud()
        
        // add tap gesture to rotate shapes
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnView.addGestureRecognizer(tapGesture)
        
        // add pan gesture to move shapes laterally
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scnView.addGestureRecognizer(panGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // try reading high scores from UserDefaults
        let defaults = UserDefaults.standard
        if let scores = defaults.array(forKey: "highScores") as? [Int] {
            highScores = scores
            highScoreInitials = defaults.stringArray(forKey: "highScoreInitials")!
        } else {
            highScores = [Int](repeating: Constants.defaultScore, count: 10)
            highScoreInitials = [String](repeating: "TET", count: 10)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        level = 0
        levelRowsCleared = 0
        levelFrameTime = Double(framesPerGridcell[level]) / framesPerSecond
        frameTime = levelFrameTime
        spawnShape()
    }

    private func spawnShape() {
        fallingShape = boardScene.spawnShape()
        targetPositionX = fallingShape.position.x  // scene coordinates
        tapGesture.isEnabled = true
        panGesture.isEnabled = true
        isShapeFalling = true
    }
    
    func moveShapeDown() {
        guard fallingShape != nil else { return }
        if !isFallingShapeContactingOn(screenSide: .bottom) {
            // move one space down (handlePan handles moving laterally)
            fallingShape.position.y -= Float(Constants.blockSpacing)
            // add score
            if motionState == .softDrop {
                hud.score += 1
                if !isPanHandled {
                    frameTime = levelFrameTime  // reset frameTime, if handlePan is not getting called fast enough
                }
                isPanHandled = false  // reset in handlePan
            } else if motionState == .hardDrop {
                hud.score += 2
            }
        } else {
            handleShapeReachingBottom()
        }
    }
        
    private func handleShapeReachingBottom() {
        // shape reached bottom, remove rows and re-spawn new shape
        panGesture.isEnabled = false  // disable panGesture (if any), so it doesn't carry over to next falling shape (re-enable in spawnShape)
        isShapeFalling = false
        frameTime = levelFrameTime
        boardScene.separateBlocksFrom(shapeNode: fallingShape)  // removes fallingShape from rootNode
        let numberOfRowsRemoved = boardScene.removeFullRows()
        levelRowsCleared += numberOfRowsRemoved
        if levelRowsCleared >= 10 {
            level += 1
            hud.level = level
            levelRowsCleared -= 10
        }
        if numberOfRowsRemoved > 0 {
            hud.score += rowRemovalPoints[numberOfRowsRemoved - 1] * (level + 1)  // original Nintendo scoring system
        }
        levelFrameTime = Double(framesPerGridcell[min(level, 29)]) / framesPerSecond
        frameTime = levelFrameTime
        // check if game over, or spawn next shape
        if fallingShape.position.y >= (Float(Constants.blocksPerSide) / 2 - 2.5) * Float(Constants.blockSpacing) {
            gameOver()
        } else {
            spawnShape()
        }
    }
    
    private func gameOver() {
        hud.isGameOver = true
        tapGesture.isEnabled = false  // disable, so tapping on "New Game" doesn't cause next falling piece to rotate (re-enable in spawnShape)
        if hud.score > highScores.min()! {
            // sort both arrays by highScore
            let combined = zip(highScores, highScoreInitials).sorted { $0.0 > $1.0 }  // returns tuple
            highScores = combined.map { $0.0 }
            highScoreInitials = combined.map { $0.1 }
            // replaced last place with new score
            highScores[highScores.count - 1] = hud.score
            highScoreInitials[highScores.count - 1] = "<<<"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                // save high scores to userDefaults, then segue to HighScoresViewController
                let defaults = UserDefaults.standard
                defaults.set(self.highScores, forKey: "highScores")
                defaults.set(self.highScoreInitials, forKey: "highScoreInitials")
                self.performSegue(withIdentifier: "Show High Scores", sender: self)  // prepare(for segue:) not needed
            }
        }
    }
    
    private func startNewGame() {  // called by clicking hud button
        hud.reset()
        boardScene.reset()
        level = 0
        levelFrameTime = Double(framesPerGridcell[level]) / framesPerSecond
        frameTime = levelFrameTime
        spawnShape()
    }

    func moveShapeAcross() {
        guard fallingShape != nil else { return }
        if targetPositionX < fallingShape.position.x {
            if !isFallingShapeContactingOn(screenSide: .left) {
                fallingShape.position.x -= Float(Constants.blockSpacing)  // just move one position at a time, to avoid overshooting edges
            } else {
                targetPositionX = fallingShape.position.x
            }
        } else if targetPositionX > fallingShape.position.x {
            if !isFallingShapeContactingOn(screenSide: .right) {
                fallingShape.position.x += Float(Constants.blockSpacing)
            } else {
                targetPositionX = fallingShape.position.x
            }
        }
    }

    // rotate fallingShape 90 deg CCW, if not blocked (move left or right, if necessary to allow rotation)
    func rotateShapeIfNotBlocked() {
        isRotationRequested = false
        
        var nudge: Float = 0.0
        var isBlocked = isShapeBlockedFromRotation()
        if isBlocked.left && isBlocked.right { return }  // blocked on both sides (return without rotating)
        let originalPositionX = fallingShape.position.x
        
        // if blocked to the left, move one position at a time to the right, until free to rotate, or until blocked to the right
        while isBlocked.left {
            nudge += Float(Constants.blockSpacing)
            fallingShape.position.x += nudge  // temporarily move right
            isBlocked = isShapeBlockedFromRotation()
            if isBlocked.right {
                fallingShape.position.x = originalPositionX
                return  // unable to move and rotate freely (return without rotating)
            }
        }
        
        // if blocked to the right, move one position at a time to the left, until free to rotate, or until blocked to the left
        while isBlocked.right {
            nudge -= Float(Constants.blockSpacing)
            fallingShape.position.x += nudge  // temporarily move left
            isBlocked = isShapeBlockedFromRotation()
            if isBlocked.left {
                fallingShape.position.x = originalPositionX
                return  // unable to move and rotate freely (return without rotating)
            }
        }
        fallingShape.position.x += nudge
        fallingShape.transform = SCNMatrix4Rotate(fallingShape.transform, .pi/2, 0, 0, 1)  // rotate 90 deg CCW
    }
    
    // determine if any of the blocks in fallingShape will overlap an external block, if fallingShape were to be rotated 90 deg CCW
    private func isShapeBlockedFromRotation() -> (left: Bool, right: Bool) {
        var isBlockedLeft = false
        var isBlockedRight = false
        var numberOfContactsBelow = 0
        var numberOfBlocksWithContacts = 0

        let finalAngle = fallingShape.eulerAngles.z + Float.pi / 2  // 90 deg CCW
        let rotateAroundZ = simd_quatf(angle: finalAngle, axis: SIMD3(0, 0, 1))
        let transform = simd_float4x4(rotateAroundZ)
        
        for blockNode in fallingShape.childNodes {
            // determine predicted rotated block position (in scene coordinates)
            let blockNodePosition4 = simd_float4(blockNode.position.x, blockNode.position.y, blockNode.position.z, 0)  // fallingShape coordinates
            let relativeRotatedPosition = simd_mul(transform, blockNodePosition4)  // fallingShape coordinates
            let absoluteRotatedPosition = SCNVector3(relativeRotatedPosition.x + fallingShape.position.x,  // scene coordinates
                                                     relativeRotatedPosition.y + fallingShape.position.y,
                                                     relativeRotatedPosition.z + fallingShape.position.z)
            let screenPosition = scnView.projectPoint(absoluteRotatedPosition)  // screen coordinates (3D)
            let location = CGPoint(x: CGFloat(screenPosition.x), y: CGFloat(screenPosition.y))  // screen coordinates (2D)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])  // .all = closest to farthest, in order
            
            if hitResults.count > 1 {  // all blocks are in contact with at least the background
                if hitResults[0].node.parent != fallingShape {  // ignore contacts with fallingShape
                    numberOfBlocksWithContacts += 1
                    let contactDistanceX = absoluteRotatedPosition.x - fallingShape.position.x  // scene coordinates
                    let contactDistanceY = absoluteRotatedPosition.y - fallingShape.position.y
                    let contactTolerance = Float(Constants.blockSpacing) / 2
                    
                    if contactDistanceY < -contactTolerance {
                        numberOfContactsBelow += 1
                    }
                    if contactDistanceX > contactTolerance {
                        isBlockedRight = true
                    } else if contactDistanceX < -contactTolerance {
                        isBlockedLeft = true
                    }
                }
            }
        }
        // don't allow rotation, if all contacts are below the center of fallingShape
        if numberOfBlocksWithContacts > 0 && numberOfBlocksWithContacts == numberOfContactsBelow {
            isBlockedLeft = true  // set both true, to prevent rotation
            isBlockedRight = true
        }
        return (isBlockedLeft, isBlockedRight)
    }
    
    // MARK: - Gesture Recognizers
    
    // rotate falling shape 90 deg CCW when tapped (unless rotation will cause contact with edges, or other blocks)
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        isRotationRequested = true  // rotation occurs at next renderer frame
    }
    
    // move shape left/right when panning across, or down when panning down
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        isPanHandled = true
        if recognizer.state == .began {
            shapeScreenStartLocation = scnView.projectPoint(fallingShape.position)
            motionState = .idle
        } else if recognizer.state == .changed {
            // Note: While the pan continues, translation continuously provides the screen position relative to the starting point (in points).
            let translation = recognizer.translation(in: scnView)  // delta screen coordinates
            let velocity = recognizer.velocity(in: scnView)
            
            if motionState == .hardDrop { return }
            let pastMotionState = motionState
            updateMotionState(panSpeed: velocity)

            switch motionState {
            case .hardDrop:
                spawnTime = 0  // force immediate start of hard drop in renderer
                frameTime = Constants.hardDropTimeFrame
            case .lateralPan:
                frameTime = levelFrameTime
                let targetScreenPosition = SCNVector3(x: self.shapeScreenStartLocation.x + Float(translation.x),
                                                      y: self.shapeScreenStartLocation.y + Float(translation.y),
                                                      z: self.shapeScreenStartLocation.z)
                let targetScenePosition = self.scnView.unprojectPoint(targetScreenPosition)
                DispatchQueue.main.async {
                    self.targetPositionX = targetScenePosition.x  // scene coordinates
                    // discretize by blockSpacing
                    self.targetPositionX = (floor(self.targetPositionX / Float(Constants.blockSpacing) - 0.5) + 0.5) * Float(Constants.blockSpacing)
                }
            case .softDrop:
                if pastMotionState != .softDrop {
                    spawnTime = 0  // force immediate start of dropping in renderer (don't keep repeating this)
                    frameTime = Constants.softDropTimeFrame
                }
            default:
                break
            }
        } else if recognizer.state == .ended {
            if motionState != .hardDrop { frameTime = levelFrameTime }
        }
    }
    
    private func updateMotionState(panSpeed: CGPoint) {
        let lateralPanSpeed = abs(panSpeed.x / 60)
        let verticalPanSpeed = panSpeed.y / 60
        
        switch motionState {
        case .idle:
            if verticalPanSpeed > Constants.hardDropPanSpeedThreshold {
                motionState = .hardDrop
            } else if lateralPanSpeed > verticalPanSpeed {
                motionState = .lateralPan
            } else if verticalPanSpeed > lateralPanSpeed + Constants.panSpeedSoftDropDeadband {
                motionState = .softDrop
            }
        case .lateralPan:
            if verticalPanSpeed > Constants.hardDropPanSpeedThreshold {
                motionState = .hardDrop
            } else if verticalPanSpeed > lateralPanSpeed + Constants.panSpeedSoftDropDeadband {
                motionState = .softDrop
            }
        case .softDrop:
            if verticalPanSpeed > Constants.hardDropPanSpeedThreshold {
                motionState = .hardDrop
            } else if lateralPanSpeed > verticalPanSpeed + Constants.panSpeedLateralDeadband {
                motionState = .lateralPan
            }
        default:
            return
        }
    }

    // MARK: - Setup
    
    private func setupView() {
        scnView = self.view as? SCNView
        scnView.showsStatistics = false  // true: show GPU resource usage and frames-per-second along bottom of scene
        scnView.allowsCameraControl = false  // false: move camera programmatically
        scnView.autoenablesDefaultLighting = false  // false: disable default (ambient) light, if another light soure is specified
        scnView.isPlaying = true  // true: prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = boardScene
        scnView.delegate = self  // needed for renderer, below
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, Constants.blockSpacing, Constants.cameraDistance)
        boardScene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLight() {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        boardScene.rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        boardScene.rootNode.addChildNode(ambientLightNode)
    }
    
    func setupHud() {
        hud = Hud(size: view.bounds.size)
        hud.setup(buttonHandler: self.startNewGame)
        scnView.overlaySKScene = hud
    }

    // MARK: - Utility Functions
    
    // determine if any bumpers on the falling shape are contacting another block or edge
    private func isFallingShapeContactingOn(screenSide: ScreenSide) -> Bool {
        var contactingBumper: SCNNode!
        for node in fallingShape.childNodes {
            if let blockNode = node as? BlockNode {
                switch screenSide {
                case .left:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.topBumper
                    case 180:
                        contactingBumper = blockNode.rightBumper
                    case -90:
                        contactingBumper = blockNode.bottomBumper
                    default:
                        contactingBumper = blockNode.leftBumper
                    }
                case .right:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.bottomBumper
                    case 180:
                        contactingBumper = blockNode.leftBumper
                    case -90:
                        contactingBumper = blockNode.topBumper
                    default:
                        contactingBumper = blockNode.rightBumper
                    }
                case .top:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.rightBumper
                    case 180:
                        contactingBumper = blockNode.bottomBumper
                    case -90:
                        contactingBumper = blockNode.leftBumper
                    default:
                        contactingBumper = blockNode.topBumper
                    }
                case .bottom:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.leftBumper
                    case 180:
                        contactingBumper = blockNode.topBumper
                    case -90:
                        contactingBumper = blockNode.rightBumper
                    default:
                        contactingBumper = blockNode.bottomBumper
                    }
                }
                boardScene.physicsWorld.updateCollisionPairs()  // force physics engine to reevalute possible contacts (may not be needed?)
                if let bumperPhysicsBody = contactingBumper.physicsBody {
                    let contactedNodes = boardScene.physicsWorld.contactTest(with: bumperPhysicsBody, options: nil)
                    // occasional crash on previous line: "EXC_BAD_ACCESS (code=1, address=0x0)" indicates
                    // something is trying to access a null pointer (this occurs after viewDidAppear).
                    for contactedNode in contactedNodes {
                        // disregard bumpers that are contacting other blocks within its own shape
                        if contactedNode.nodeA.parent != fallingShape && contactedNode.nodeB.parent != fallingShape {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
}

extension TetrisViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isRotationRequested {
            rotateShapeIfNotBlocked()
        } else {
            moveShapeAcross()  // not sure if it's important to prevent rotation and translation in the same frame
        }
        if isShapeFalling {
            if time > spawnTime {
                spawnTime = time + frameTime
                moveShapeDown()
            }
        }
    }
}
