import Foundation
import SceneKit

class HomeVisualization3D: ObservableObject {
    static let shared = HomeVisualization3D()
    @Published var scene: SCNScene?
    @Published var deviceNodes: [String: SCNNode] = [:]
    
    func create3DModel(rooms: [Room3D]) {
        scene = SCNScene()
        
        for room in rooms {
            let roomNode = createRoomNode(room)
            scene?.rootNode.addChildNode(roomNode)
        }
    }
    
    private func createRoomNode(_ room: Room3D) -> SCNNode {
        let node = SCNNode()
        node.position = SCNVector3(room.x, room.y, room.z)
        return node
    }
}

struct Room3D {
    let name: String
    let x: Float
    let y: Float
    let z: Float
    let width: Float
    let height: Float
    let depth: Float
}