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
    
    func setupTouch() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        self.addGestureRecognizer(tap)
        
        let longTouch = UILongPressGestureRecognizer(target: self, action: #selector(longTouchAction(_:)))
        self.addGestureRecognizer(longTouch)
    }
    
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
