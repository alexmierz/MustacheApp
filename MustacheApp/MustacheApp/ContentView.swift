//
//  ContentView.swift
//  MustacheApp
//
//  Created by Alex Mierzejewski on 6/9/23.
//


import SwiftUI
import ARKit
import ReplayKit
import AVKit
import SQLite

class ScreenRecordingDelegate: NSObject, RPPreviewViewControllerDelegate {
    weak var presentationContext: UIViewController?

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true) {
            if let playerViewController = previewController as? AVPlayerViewController,
               let videoURL = playerViewController.player?.currentItem?.asset as? AVURLAsset {
                // Save video to camera roll
                UISaveVideoAtPathToSavedPhotosAlbum(videoURL.url.path, nil, nil, nil)
                
                // Save video URL to SQLite database
                self.saveVideoURLToDatabase(videoURL: videoURL.url)
            }
            self.presentationContext?.dismiss(animated: true)
        }
    }
    
    func saveVideoURLToDatabase(videoURL: URL) {
        // SQLite database path
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let databasePath = dbPath.appending("/videos.db")
        
        do {
            // Connect to SQLite database
            let db = try Connection(databasePath)
            
            // Create videos table if it doesn't exist
            let videosTable = Table("videos")
            let id = Expression<Int64>("id")
            let url = Expression<String>("url")
            let createTableQuery = videosTable.create(ifNotExists: true) { table in
                table.column(id, primaryKey: .autoincrement)
                table.column(url)
            }
            try db.run(createTableQuery)
            
            // Insert video URL into videos table
            let insertQuery = videosTable.insert(url <- videoURL.absoluteString)
            try db.run(insertQuery)
        } catch {
            print("Error saving video URL to database: \(error)")
        }
    }
}

struct ContentView: SwiftUI.View {
    @State private var isRecording = false
    let delegate = ScreenRecordingDelegate()
    @State private var showLibrary = false
    
    var body: some SwiftUI.View {
        ZStack {
            ARFaceView()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .padding()
                        .background(isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showLibrary = true
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            delegate.presentationContext = UIApplication.shared.windows.first?.rootViewController
        }
        .sheet(isPresented: $showLibrary) {
            
            LibraryGridView()
        }
    }

    private func startRecording() {
        let recorder = RPScreenRecorder.shared()
        guard recorder.isAvailable else {
            print("Screen recording is not available.")
            return
        }

        recorder.isMicrophoneEnabled = true // Enable microphone audio recording

        recorder.startRecording { error in
            if let error = error {
                print("Recording failed to start: \(error.localizedDescription)")
            } else {
                print("Recording started.")
            }
            isRecording = true
        }
    }

    private func stopRecording() {
        let recorder = RPScreenRecorder.shared()
        recorder.stopRecording { [self] previewViewController, error in
            if let error = error {
                print("Recording failed to stop: \(error.localizedDescription)")
            } else if let previewViewController = previewViewController {
                previewViewController.previewControllerDelegate = delegate
                delegate.presentationContext?.present(previewViewController, animated: true, completion: nil)
            }
            isRecording = false
        }
    }
}

struct ARFaceView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
        
        //Tap through mustaches
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
            //print(featureIndices)
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

struct LibraryGridView: SwiftUI.View {
    @State private var videos: [URL] = []
    
    var body: some SwiftUI.View {
        ScrollView {
            VStack {
                Text("Video Library")
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(videos, id: \.self) { videoURL in
                        VideoItemView(videoURL: videoURL)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchVideosFromDatabase()
        }
    }
    
    private func fetchVideosFromDatabase() {
        // Fetch videos from SQLite database and update
        let urls: [URL] = []
        
        DispatchQueue.main.async {
            videos = urls
        }
    }
}



struct VideoItemView: SwiftUI.View {
    var videoURL: URL
    
    var body: some SwiftUI.View {
        VStack {
            Text("Video")
                .font(.headline)
            
            // Attempted display of video thumbnail
            Image(systemName: "film")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            
            // Attempted display of video name
            Text(videoURL.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
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
        }
    }
}
