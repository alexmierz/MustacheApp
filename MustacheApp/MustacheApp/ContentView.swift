//
//  ContentView.swift
//  MustacheApp
//
//  Created by Alex Mierzejewski on 6/9/23.
//



import SwiftUI
import ARKit
import Realm
import RealmSwift

struct ContentView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
        
        // Enable user interaction and add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.isUserInteractionEnabled = true
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        let noseOptions = ["nose01", "nose02", "nose03"]
        let features = ["nose"]
        var featureIndices = [[6]]
        var faceNode: FaceNode?
        
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            let node = SCNNode()
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let device = MTLCreateSystemDefaultDevice() else {
                return nil
            }
            
            let faceGeometry = ARSCNFaceGeometry(device: device)
            faceGeometry?.firstMaterial?.colorBufferWriteMask = []
            
            let faceNode = SCNNode(geometry: faceGeometry)
            
            self.faceNode = FaceNode(with: noseOptions)
            self.faceNode?.name = "nose"
            faceNode.addChildNode(self.faceNode!)
            
            updateFeatures(for: faceNode, using: faceAnchor)
            
            node.addChildNode(faceNode)
            return node
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.childNodes.first?.geometry as? ARSCNFaceGeometry else {
                return
            }
            
            faceGeometry.update(from: faceAnchor.geometry)
            updateFeatures(for: node.childNodes.first, using: faceAnchor)
        }
        
        func updateFeatures(for node: SCNNode?, using anchor: ARFaceAnchor) {
            print(featureIndices)
            for (feature, indices) in zip(features, featureIndices) {
                let child = node?.childNode(withName: feature, recursively: false) as? FaceNode
                let vertices = indices.map { SCNVector3(anchor.geometry.vertices[$0]) }
                child?.updatePosition(for: vertices)
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            faceNode?.next()
        }
    }
}

class FaceNode: SCNNode {
    var options: [String]
    var index = 0
    
    init(with options: [String], width: CGFloat = 0.06, height: CGFloat = 0.06) {
        self.options = options
        
        super.init()
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = UIImage(named: options.first!)
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.transparency = 1.0
        
        geometry = plane
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updatePosition(for vectors: [SCNVector3]) {
        var newPos = SCNVector3()
        for vector in vectors {
            newPos.x += vector.x
            newPos.y += vector.y
            newPos.z += vector.z
        }
        newPos.x /= Float(vectors.count)
        newPos.y /= Float(vectors.count)
        newPos.z /= Float(vectors.count)
        
        let distanceFromFace: Float = 0.01 // Adjust this value as needed
        let length = sqrt(newPos.x * newPos.x + newPos.y * newPos.y + newPos.z * newPos.z)
        let direction = SCNVector3(newPos.x / length, newPos.y / length, newPos.z / length)
        let offset = SCNVector3(direction.x * distanceFromFace, direction.y * distanceFromFace, direction.z * distanceFromFace)
        position = SCNVector3(newPos.x + offset.x, newPos.y + offset.y, newPos.z + offset.z)
    }
    
    func next() {
        index = (index + 1) % options.count
        
        if let plane = geometry as? SCNPlane {
            plane.firstMaterial?.diffuse.contents = UIImage(named: options[index])
            plane.firstMaterial?.isDoubleSided = true
        }
    }
}


