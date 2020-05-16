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
    static let blocksPerBase = 12       // frame dimension
    static let blocksPerSide = 22       // frame dimension
    static let respawnDelay = 0.3       // seconds
    static let hardDropTimeFrame = 0.01 // seconds
    static let hardDropPanThreshold: CGFloat = 30.0  // y-points/pan frame to start hard drop
    static let panThreshold: CGFloat = 1.0  // points/pan frame to start movement
}

class TetrisViewController: UIViewController {
    
    var scnView: SCNView!
    var cameraNode: SCNNode!

    let boardScene = BoardScene()
    var hud = Hud()

    var panGesture = UIPanGestureRecognizer()
    var targetPositionX: Float = 0.0
    var targetPositionY: Float = 0.0
    var pastTranslationX: CGFloat = 0.0
    var pastTranslationY: CGFloat = 0.0
    var fallingShape: ShapeNode!
    var isShapeFalling = false
    var isHardDrop = false
    var isShapeRotating = false
    var nudge: Float = 0.0
    var spawnTime: TimeInterval = 0
    var frameTime = 1.0  // seconds, affect speed of shapes falling
    var savedFrameTime = 1.0  // saved during hard drop
    var shapeScreenStartLocation: SCNVector3!

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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnView.addGestureRecognizer(tapGesture)
        
        // add pan gesture to move shapes laterally
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scnView.addGestureRecognizer(panGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spawnShape()
    }

    private func spawnShape() {
        fallingShape = boardScene.spawnShape()
        targetPositionX = fallingShape.position.x  // scene coordinates
        targetPositionY = fallingShape.position.y  // scene coordinates
        panGesture.isEnabled = true
        isShapeFalling = true
    }
    
    func moveShapeDownAutomatically() {
        guard fallingShape != nil else { return }
        if !isFallingShapeContactingOn(screenSide: .bottom) {
            // move one space down (handlePan handles moving laterally)
            fallingShape.position.y -= Float(Constants.blockSpacing)
        } else {
            handleShapeReachingBottom()
        }
    }
    
    func moveShapeDownManually() {
        guard fallingShape != nil else { return }
        if targetPositionY < fallingShape.position.y {
            if !isFallingShapeContactingOn(screenSide: .bottom) {
                fallingShape.position.y -= Float(Constants.blockSpacing)  // just move one position at a time, to avoid overshooting edges
            } else {
                handleShapeReachingBottom()
            }
        }
    }
        
    private func handleShapeReachingBottom() {
        // shape reached bottom, remove rows and re-spawn new shape
        panGesture.isEnabled = false  // cancel any existing panGesture, so it doesn't carry over to next falling shape
        isHardDrop = false  // this line must come after disabling panGesture
        isShapeFalling = false
        frameTime = savedFrameTime
        boardScene.separateBlocksFrom(shapeNode: fallingShape)  // removes fallingShape from rootNode
        hud.score += 100 * boardScene.removeFullRows()
        if fallingShape.position.y >= (Float(Constants.blocksPerSide) / 2 - 2.5) * Float(Constants.blockSpacing) {
            hud.isGameOver = true
        } else {
            spawnShape()
        }
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

    func rotateShape() {
        isShapeRotating = false
        fallingShape.position.x += nudge  // for some reason, nudge has to be applied again, here (also in handleTap)
        fallingShape.transform = SCNMatrix4Rotate(fallingShape.transform, .pi/2, 0, 0, 1)
    }
    
    private func isShapeBlockedFromRotation() -> (left: Bool, right: Bool) {
        var isBlockedLeft = false
        var isBlockedRight = false

        let finalAngle = fallingShape.eulerAngles.z + Float.pi / 2
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
                    let contactDistance = absoluteRotatedPosition.x - fallingShape.position.x  // scene coordinates
                    if contactDistance > Float(Constants.blockSpacing / 2) {
                        isBlockedRight = true
                    } else if contactDistance < -Float(Constants.blockSpacing / 2) {
                        isBlockedLeft = true
                    }
                }
            }
        }
        return (isBlockedLeft, isBlockedRight)
    }
    
    // MARK: - Gesture Recognizers
    
    // rotate falling shape 90 deg CCW when tapped (unless rotation will cause contact with edge, or another block)
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        nudge = 0.0
        var isBlocked = isShapeBlockedFromRotation()
        if isBlocked.left && isBlocked.right { return }  // can't rotate
        let originalPositionX = fallingShape.position.x
        while isBlocked.left {
            nudge += Float(Constants.blockSpacing)
            fallingShape.position.x += Float(Constants.blockSpacing)
            isBlocked = isShapeBlockedFromRotation()
            if isBlocked.right {
                fallingShape.position.x = originalPositionX
                return  // can't rotate
            }
        }
        while isBlocked.right {
            nudge -= Float(Constants.blockSpacing)
            fallingShape.position.x -= Float(Constants.blockSpacing)
            isBlocked = isShapeBlockedFromRotation()
            if isBlocked.left {
                fallingShape.position.x = originalPositionX
                return  // can't rotate
            }
        }
        isShapeRotating = true
    }
    
    // move shape left/right when panning across, or down when panning down
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        guard !isHardDrop else { return }  // don't assess panning, during hard drop
        if recognizer.state == .began {
            shapeScreenStartLocation = scnView.projectPoint(fallingShape.position)
            pastTranslationX = 0.0
            pastTranslationY = 0.0
        } else if recognizer.state == .changed {  // don't want to run when state = .ended (fallingShape reached bottom)
            targetPositionY = fallingShape.position.y
            // Note: While the pan continues, translation continuously provides the screen position relative to the starting point (in points).
            let translation = recognizer.translation(in: scnView)  // delta screen coordinates
            if translation.y - pastTranslationY > Constants.hardDropPanThreshold {
                // pan down fast, hard drop
                isHardDrop = true
                savedFrameTime = frameTime
                spawnTime = 0  // force immediate start of dropping in renderer
                frameTime = Constants.hardDropTimeFrame
                pastTranslationY = translation.y
            } else {
                // pan across, move shape laterally (actual move is in renderer)
                DispatchQueue.main.async {
                    let targetScreenPosition = SCNVector3(x: self.shapeScreenStartLocation.x + Float(translation.x),
                                                          y: self.shapeScreenStartLocation.y + Float(translation.y),
                                                          z: self.shapeScreenStartLocation.z)
                    let targetScenePosition = self.scnView.unprojectPoint(targetScreenPosition)
                    if abs(translation.x - self.pastTranslationX) > Constants.panThreshold {
                        self.targetPositionX = targetScenePosition.x  // scene coordinates
                        // discretize by blockSpacing
                        self.targetPositionX = (floor(self.targetPositionX / Float(Constants.blockSpacing) - 0.5) + 0.5) * Float(Constants.blockSpacing)
                    }
                    if abs(translation.y - self.pastTranslationY) > Constants.panThreshold {
                        self.targetPositionY = targetScenePosition.y  // scene coordinates
                        self.targetPositionY = (floor(self.targetPositionY / Float(Constants.blockSpacing) - 0.5) + 0.5) * Float(Constants.blockSpacing)
                    }
                    self.pastTranslationX = translation.x
                    self.pastTranslationY = translation.y
                }
            }
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
        hud.setup()
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
                let contactedNodes = boardScene.physicsWorld.contactTest(with: contactingBumper.physicsBody!, options: nil)
                for contactedNode in contactedNodes {
                    // disregard bumpers that are contacting other blocks within its own shape
                    if contactedNode.nodeA.parent != fallingShape && contactedNode.nodeB.parent != fallingShape {
                        return true
                    }
                }
            }
        }
        return false
    }
}

extension TetrisViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if isShapeRotating {
            rotateShape()
        }
        if isShapeFalling {
            if time > spawnTime {
                spawnTime = time + frameTime
                moveShapeDownAutomatically()
            }
        }
        moveShapeAcross()
        moveShapeDownManually()
    }
}
