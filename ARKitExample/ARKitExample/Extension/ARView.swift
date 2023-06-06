//
//  ARView.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import UIKit
import ARKit
import RealityKit

extension ARView: ARCoachingOverlayViewDelegate {
    
    func addCoaching() {
        let coachingOverLay = ARCoachingOverlayView()
        coachingOverLay.delegate = self
        coachingOverLay.session = self.session
        coachingOverLay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverLay.goal = .anyPlane
        self.addSubview(coachingOverLay)
    }
    
    func touchAndGenerateModel(handler: Selector) {

    }

    
//    func setupTouch() {
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
//        self.addGestureRecognizer(tap)
//
//        let longTouch = UILongPressGestureRecognizer(target: self, action: #selector(longTouchAction(_:)))
//        self.addGestureRecognizer(longTouch)
//    }
    
    /// 모델 터치 이벤트
    @objc func tapAction(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: self) else { return }
        guard let rayResult = self.ray(through: touchInView) else { return } // 선택한 화면의 위치에 있는 AR 오브젝트
        let result = self.scene.raycast(origin: rayResult.origin, direction: rayResult.direction)
        if let firstResult = result.first {
            let model = firstResult.entity
            
            var trans = Transform()
            trans.rotation = simd_quatf(angle: Float.pi, axis: SIMD3(x: 0, y: 1, z: 0)) // 변경되는 축 선택
            model.move(to: trans, relativeTo: model, duration: 2)
        }
    }
    
    // 모델 롱 터치 이벤트
    @objc func longTouchAction(_ sender: UILongPressGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: self) else { return }
        guard let rayResult = self.ray(through: touchInView) else { return } // 선택한 화면의 위치에 있는 AR 오브젝트
        let result = self.scene.raycast(origin: rayResult.origin, direction: rayResult.direction)
        if let firstResult = result.first {
            let model = firstResult.entity
            // 삭제
            model.removeFromParent()
        }
    }
}


///
extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension ARMeshClassification {
    var description: String {
        switch self {
        case .ceiling: return "Ceiling"
        case .door: return "Door"
        case .floor: return "Floor"
        case .seat: return "Seat"
        case .table: return "Table"
        case .wall: return "Wall"
        case .window: return "Window"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
    }
    
    var color: UIColor {
        switch self {
        case .ceiling: return .cyan
        case .door: return .brown
        case .floor: return .red
        case .seat: return .purple
        case .table: return .yellow
        case .wall: return .green
        case .window: return .blue
        case .none: return .lightGray
        @unknown default: return .gray
        }
    }
}

extension Transform {
    static func * (left: Transform, right: Transform) -> Transform {
        return Transform(matrix: simd_mul(left.matrix, right.matrix))
    }
}

extension ARMeshGeometry {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
    
    /// To get the mesh's classification, the sample app parses the classification's raw data and instantiates an
    /// `ARMeshClassification` object. For efficiency, ARKit stores classifications in a Metal buffer in `ARMeshGeometry`.
    func classificationOf(faceWithIndex index: Int) -> ARMeshClassification {
        guard let classification = classification else { return .none }
        assert(classification.format == MTLVertexFormat.uchar, "Expected one unsigned char (one byte) per classification")
        let classificationPointer = classification.buffer.contents().advanced(by: classification.offset + (classification.stride * index))
        let classificationValue = Int(classificationPointer.assumingMemoryBound(to: CUnsignedChar.self).pointee)
        return ARMeshClassification(rawValue: classificationValue) ?? .none
    }
    
    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
        let vertexCountPerFace = faces.indexCountPerPrimitive
        let vertexIndicesPointer = faces.buffer.contents()
        var vertexIndices = [UInt32]()
        vertexIndices.reserveCapacity(vertexCountPerFace)
        for vertexOffset in 0..<vertexCountPerFace {
            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
        }
        return vertexIndices
    }
    
    func verticesOf(faceWithIndex index: Int) -> [(Float, Float, Float)] {
        let vertexIndices = vertexIndicesOf(faceWithIndex: index)
        let vertices = vertexIndices.map { vertex(at: $0) }
        return vertices
    }
    
    func centerOf(faceWithIndex index: Int) -> (Float, Float, Float) {
        let vertices = verticesOf(faceWithIndex: index)
        let sum = vertices.reduce((0, 0, 0)) { ($0.0 + $1.0, $0.1 + $1.1, $0.2 + $1.2) }
        let geometricCenter = (sum.0 / 3, sum.1 / 3, sum.2 / 3)
        return geometricCenter
    }
}

extension Scene {
    // Add an anchor and remove it from the scene after the specified number of seconds.
/// - Tag: AddAnchorExtension
    func addAnchor(_ anchor: HasAnchoring, removeAfter seconds: TimeInterval) {
        guard let model = anchor.children.first as? HasPhysics else {
            return
        }
        
        // Set up model to participate in physics simulation
        if model.collision == nil {
            model.generateCollisionShapes(recursive: true)
            model.physicsBody = .init()
        }
        // ... but prevent it from being affected by simulation forces for now.
        model.physicsBody?.mode = .kinematic
        
        addAnchor(anchor)
        // Making the physics body dynamic at this time will let the model be affected by forces.
        Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { (timer) in
            model.physicsBody?.mode = .dynamic
        }
        Timer.scheduledTimer(withTimeInterval: seconds + 3, repeats: false) { (timer) in
            self.removeAnchor(anchor)
        }
    }
}

