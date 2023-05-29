//
//  ARViewModel.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import UIKit
import ARKit
import RxSwift
import RxRelay
import RealityKit

class ARViewModel {
    //MARK: - Properties
    let network: NetworkManager
    let disposeBag = DisposeBag()
    let motionData = PublishRelay<MotionModel>()
    
    //MARK: - Lifecycle
    init(ip: String, port: Int32) {
        self.network = NetworkManager(ip: ip, port: port)
        bind()
    }
    
    //MARK: - Methods
    func setupARConfiguration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        return config
    }
    
    func getModelEntity(_ model: ModelName) -> ModelEntity {
        let modelEntity = try! ModelEntity.loadModel(named: model.rawValue)
        modelEntity.generateCollisionShapes(recursive: true)
        return modelEntity
    }
    
    //MARK: - Bind
    private func bind() {
        motionData.subscribe { [weak self] data in
            guard let data = data.element else { return }
            self?.network.sendBinaryData(motionData: data)
        }
        .disposed(by: disposeBag)
    }
    
    //MARK: - ARCameraFrame
    func processARCamera(currentFrame: ARFrame) {
        let cameraTransform = currentFrame.camera.transform
        
        let rowPosition = cameraTransform.columns.3
        let orientation = simd_quaternion(cameraTransform)
//        let euler = currentFrame.camera.eulerAngles
        
        // 가공
        let position = Position(x: rowPosition.x.rounded(toPlaces: 2),
                                y: rowPosition.y.rounded(toPlaces: 2),
                                z: rowPosition.z.rounded(toPlaces: 2))
        let quaternion = Quaternion(x: orientation.imag.x.rounded(toPlaces: 2),
                                    y: orientation.imag.y.rounded(toPlaces: 2),
                                    z: orientation.imag.z.rounded(toPlaces: 2),
                                    w: orientation.real.rounded(toPlaces: 2))
        motionData.accept(MotionModel(position: position, quaternion: quaternion))
    }
}
