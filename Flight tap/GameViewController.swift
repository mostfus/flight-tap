//
//  GameViewController.swift
//  Flight tap
//
//  Created by Александр Соколов on 02.12.2020.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    
    // MARK: - Outlets
    let button = UIButton()
    let scoreLabel = UILabel()

    // MARK: - Stored Properties
    var duration: TimeInterval = 5
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var ship: SCNNode!
    var scene: SCNScene!
    var scnView: SCNView!
    
    // MARK: - Methods
    
    ///  Adds a button to the scene
    func addButton() {
        // button coordinates
        let midX = scnView.frame.midX
        let midY = scnView.frame.midY
        let width: CGFloat = 200
        let height: CGFloat = 100
        button.frame = CGRect(x: midX - width / 2, y: midY - height / 2, width: width, height: height)
        
        // configure button
        button.backgroundColor = .red
        button.isHidden = true
        button.layer.cornerRadius = 15
        button.setTitle("Restart", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        
        // ad action to the button
        button.addTarget(self, action: #selector(newGame), for: .touchUpInside)
        
        // add button to the scene
        scnView.addSubview(button)
    }
    
    
    /// Adds label to the scene view
    func addScoreLabel() {
        scoreLabel.font = UIFont.systemFont(ofSize: 30)
        scoreLabel.frame = CGRect(x: 0, y: 0, width: scnView.frame.width, height: 100)
        scoreLabel.numberOfLines = 2
        scoreLabel.textAlignment = .center
        scnView.addSubview(scoreLabel)
        score = 0
    }
    
    // Create description for func - cmd + alt + /
    /// Clones new ship from the scene
    /// - Returns: SCNNode with new ship
    func getShip() -> SCNNode {
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        ship = scene.rootNode.childNode(withName: "ship", recursively: true)!.clone()
        
        // move ship far away
        let x = Int.random(in: -25 ... 25)
        let y = Int.random(in: -25 ... 25)
        let z = -105
        ship.position = SCNVector3(x, y, z)
        ship.look(at: SCNVector3(2 * x, 2 * y, 2 * z))
        
        // animation to move the ship to origin
        ship.runAction(.move(to: SCNVector3(), duration: duration), completionHandler: {
            self.ship.removeFromParentNode()
            DispatchQueue.main.async {
                self.button.isHidden = false
                self.scoreLabel.text = "Game over.\nScore: \(self.score)"
            }
        })
        
        return ship
    }
    
    @objc func newGame() {
        button.isHidden = true
        duration = 5
        score = 0
        ship = getShip()
        addShip()
    }
    
    
    /// Adds ship to the scene
    func addShip() {
        scene.rootNode.addChildNode(ship)
    }
    
    
    /// Finds and removes the ship from the scene
    func removeShip () {
        scene.rootNode.childNode(withName: "ship", recursively: true)?.removeFromParentNode()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // remove the ship
        removeShip()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
//        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
//        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        scnView = self.view as? SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        // add ship to the scene
        ship = getShip()
        addShip()
    
        // add button and scoreLabel
        addButton()
        addScoreLabel()

    }
    
    // MARK: - Actions
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                self.duration *= 0.9
                self.ship.removeFromParentNode()
                self.score += 1
                self.ship = self.getShip()
                self.addShip()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    // MARK: - Computed Properties
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

}
