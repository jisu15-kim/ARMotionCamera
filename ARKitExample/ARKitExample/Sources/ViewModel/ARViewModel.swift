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
        config.sceneReconstruction = .meshWithClassification
        return config
    }
    
    func getModelEntity(_ model: ModelName) -> ModelEntity {
        let modelEntity = try! ModelEntity.loadModel(named: model.rawValue)
//        modelEntity.generateCollisionShapes(recursive: true)
        return modelEntity
    }
    
    //MARK: - Bind
    private func bind() {
        motionData.subscribe { [weak self] data in
            guard let data = data.element else { return }
            self?.network.sendBinaryData(_motionData: data)
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
        let position = Position(x: rowPosition.x,
                                y: rowPosition.y,
                                z: rowPosition.z)
        let quaternion = Quaternion(x: orientation.imag.x,
                                    y: orientation.imag.y,
                                    z: orientation.imag.z,
                                    w: orientation.real)
        motionData.accept(MotionModel(position: position, quaternion: quaternion))
    }
}
