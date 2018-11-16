//
//  ViewController.swift
//  FloorIsLava
//
//  Created by Arielle Vaniderstine on 2017-06-06.
//  Copyright © 2017 Arielle Vaniderstine. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Tell the session to automatically detect horizontal planes
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        // Create a SceneKit plane to visualize the node using its position and extent.

        // Create the geometry and its materials
        let plane: SCNGeometry
        // Create a node with the plane geometry we created
        let planeNode = SCNNode()

        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.

        if #available(iOS 11.3, *) {
            plane = ARSCNPlaneGeometry(device: MTLCreateSystemDefaultDevice()!) ?? ARSCNPlaneGeometry()
            (plane as! ARSCNPlaneGeometry).update(from: anchor.geometry)
        } else {
            // Fallback on earlier versions
            plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
            planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        }

        planeNode.geometry = plane

        let lavaImage = UIImage(named: "Lava")
        let lavaMaterial = SCNMaterial()
        lavaMaterial.diffuse.contents = lavaImage
        lavaMaterial.isDoubleSided = true

        plane.materials = [lavaMaterial]


        return planeNode
    }

    /// Update the geometry of the node when anchor updates
    ///
    /// - Parameters:
    ///   - node: root node for the anchor
    ///   - anchor: ARPlaneAnchor of the detected surface
    func updateGeometry(of node: SCNNode, with anchor: ARPlaneAnchor) {
        guard let firstChild = node.childNodes.first else {
            return
        }
        if #available(iOS 11.3, *), let plane = firstChild.geometry as? ARSCNPlaneGeometry {
            plane.update(from: anchor.geometry)
        } else if let plane = node.geometry as? SCNPlane {
            plane.width = CGFloat(anchor.extent.x)
            plane.height = CGFloat(anchor.extent.z)
            node.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        }
    }

    // Try with a floor node instead - this didn't work so well but leaving in for reference
    func createFloorNode(anchor: ARPlaneAnchor) -> SCNNode {
        let floor = SCNFloor()

        let lavaImage = UIImage(named: "Lava")

        let lavaMaterial = SCNMaterial()
        lavaMaterial.diffuse.contents = lavaImage
        lavaMaterial.isDoubleSided = true

        floor.materials = [lavaMaterial]

        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)

        return floorNode
    }

    // MARK: - ARSCNViewDelegate


    // The following functions are automatically called when the ARSessionView adds, updates, and removes anchors

    // When a plane is detected, make a planeNode for it
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = createPlaneNode(anchor: planeAnchor)
        
        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }

    // When a detected plane is updated, make a new planeNode
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        self.updateGeometry(of: node, with: planeAnchor)
    }

}
