//
//  ViewController.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/08.
//

import UIKit
import RxSwift
import RxCocoa
import RealityKit
import ARKit
import SnapKit

class ARViewController: UIViewController {
    //MARK: - Properties
    var planeEntities: [ARAnchor : ModelEntity] = [:]

    let viewModel: ARViewModel
    var disposeBag = DisposeBag()
    var arView = ARView(frame: .zero)
    
    let scanningDebugToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        return toggle
    }()
    
    let debugLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.text = "N/A"
        label.numberOfLines = 0
        return label
    }()
    
    lazy var debugView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.4)
        view.addSubview(debugLabel)
        debugLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        return view
    }()

    var modelsForClassification: [ARMeshClassification: ModelEntity] = [:]
    
    //MARK: - LifeCycle
    init(viewModel: ARViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bind()
        setupARKit()
    }
    //MARK: - Bind
    private func bind() {
        
        scanningDebugToggle.rx.isOn
            .bind { [weak self] bool in
                if bool == true {
                    self?.arView.debugOptions.insert(.showSceneUnderstanding)
                } else {
                    self?.arView.debugOptions.remove(.showSceneUnderstanding)
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.motionData
            .bind { [weak self] data in
                guard let self = self else { return }
                self.debugLabel.text =
                "Position \nX: \(data.position.x) / Y: \(data.position.y) / Z: \(data.position.z) \nQuaternion \nX: \(data.quaternion.x) / Y: \(data.quaternion.y) / Z: \(data.quaternion.z) / W: \(data.quaternion.w)"
            }
            .disposed(by: disposeBag)
    }
    
    //MARK: - SetupAR
    private func setupARKit() {
        arView.session.delegate = self
        arView.environment.sceneUnderstanding.options = []
        arView.environment.sceneUnderstanding.options.insert(.occlusion) // 가상오브젝트의 가려짐 구현 (Mixed Reality)
        arView.environment.sceneUnderstanding.options.insert(.physics) // 실제 세계의 3D 메시를 통한 물리 시뮬레이션 구현
        // 일부 렌더링 옵션 비활성화(퍼포먼스)
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        
        arView.addCoaching()
        arView.session.run(viewModel.setupARConfiguration()) // ARSession 자동설정 비활성화
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapScreen(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - Selector
    @objc func didTapScreen(_ recognizer: UIGestureRecognizer) {
        
        /// 1. Ray-Cast 방식으로 터치한 좌표로 실제 공간 좌표 찾기
        /// Note: Ray-cast option ".estimatedPlane" with alignment ".any" also takes the mesh into account.
        let tapLocation = recognizer.location(in: arView)
        if let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any).first {
            
            /// 2. Ray와 표면의 교차점에 3D 오브젝트 생성, ARView에 추가
            let resultAnchor = AnchorEntity(world: result.worldTransform)
            resultAnchor.addChild(viewModel.getModelEntity(.cup))
            arView.scene.addAnchor(resultAnchor, removeAfter: 3)

            /// 3. 탭한 위치 주변의 표면 분류를 찾기
            /// 바닥, 벽, 문, 창문, 테이블 등
            nearbyFaceWithClassification(to: result.worldTransform.position) { (centerOfFace, classification) in
                // ...
                DispatchQueue.main.async {
                    /// 4. 현실 공간에 텍스트 배치
                    /// 사용자 시점에 따라 조금 이동, 메시에 가려지지 않도록 함
                    let rayDirection = normalize(result.worldTransform.position - self.arView.cameraTransform.translation)
                    let textPositionInWorldCoordinates = result.worldTransform.position - (rayDirection * 0.1)
                    
                    // 5. 특정 분류 나타내는 3D 텍스트 생성
                    let textEntity = self.generateClassficationTextModel(for: classification)

                    /// 6. 텍스트 크기를 Ray-Cast 결과와 카메라 사이의 거리에 따라 조절함 -> 항상 스크린에서 동일한 크기로 보이도록 설정
                    let raycastDistance = distance(result.worldTransform.position, self.arView.cameraTransform.translation)
                    textEntity.scale = .one * raycastDistance

                    /// 7. 3D 텍스트를 AR Session에 추가하고, 텍스트가 사용자를 바라보도록 설정함
                    var resultWithCameraOrientation = self.arView.cameraTransform
                    resultWithCameraOrientation.translation = textPositionInWorldCoordinates
                    let textAnchor = AnchorEntity(world: resultWithCameraOrientation.matrix)
                    textAnchor.addChild(textEntity)
                    self.arView.scene.addAnchor(textAnchor, removeAfter: 3)

                    // 8. 탭 위치 근처에 어떤 면이 감지되었다면, 그 면의 중심을 시각화함, 면의 분류에 따라 다른 색상 사용
                    if let centerOfFace = centerOfFace {
                        let faceAnchor = AnchorEntity(world: centerOfFace)
                        faceAnchor.addChild(self.sphere(radius: 0.01, color: classification.color))
                        self.arView.scene.addAnchor(faceAnchor, removeAfter: 3)
                    }
                }
            }
        }
    }
    
    //MARK: - AR Methods
    func sphere(radius: Float, color: UIColor) -> ModelEntity {
        let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        // Move sphere up by half its diameter so that it does not intersect with the mesh
        sphere.position.y = radius
        return sphere
    }
    
    //MARK: - 평면 인식
    func nearbyFaceWithClassification(to location: SIMD3<Float>, completionBlock: @escaping (SIMD3<Float>?, ARMeshClassification) -> Void) {
        /// 1. guard 언래핑
        guard let frame = arView.session.currentFrame else {
            completionBlock(nil, .none)
            return
        }

        /// 2. 현 프레임의 모든 앵커를 ARMeshAnchor로 변환
        /// 주어진 위치로부터 거리에 따라 정렬
        /// cutOffDistance - 너무 먼 앵커 제거 offset
        var meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        let cutoffDistance: Float = 4.0
        meshAnchors.removeAll { distance($0.transform.position, location) > cutoffDistance }
        meshAnchors.sort { distance($0.transform.position, location) < distance($1.transform.position, location) }

        DispatchQueue.global().async {
            ///3.  정렬한 Anchor들을 for문 돌려서 검색 (비동기)
            ///분류가 있다면 화면에 표시
            for anchor in meshAnchors {
                
                for index in 0..<anchor.geometry.faces.count {
                    // Get the center of the face so that we can compare it to the given location.
                    let geometricCenterOfFace = anchor.geometry.centerOf(faceWithIndex: index)
                    
                    // Convert the face's center to world coordinates.
                    var centerLocalTransform = matrix_identity_float4x4
                    centerLocalTransform.columns.3 = SIMD4<Float>(geometricCenterOfFace.0, geometricCenterOfFace.1, geometricCenterOfFace.2, 1)
                    let centerWorldPosition = (anchor.transform * centerLocalTransform).position
                     
                    let distanceToFace = distance(centerWorldPosition, location)
                    
                    /// 4. 선택한 위치로부터 5cm 이내 거리에 분류되는 것이 있다면, 결과 escaping closure로 반환하기
                    if distanceToFace <= 0.05 {
                        let classification: ARMeshClassification = anchor.geometry.classificationOf(faceWithIndex: index)
                        completionBlock(centerWorldPosition, classification)
                        return
                    }
                }
            }
            
            /// 5. 찾지 못했다면 (nil, .none) 반환하기
            completionBlock(nil, .none)
        }
    }
    
    func generateClassficationTextModel(for classification: ARMeshClassification) -> ModelEntity {
        // Return cached model if available
        if let model = modelsForClassification[classification] {
            model.transform = .identity
            return model.clone(recursive: true)
        }
        
        // Generate 3D text for the classification
        let lineHeight: CGFloat = 0.05
        let font = MeshResource.Font.systemFont(ofSize: lineHeight)
        let textMesh = MeshResource.generateText(classification.description, extrusionDepth: Float(lineHeight * 0.1), font: font)
        let textMaterial = SimpleMaterial(color: classification.color, isMetallic: true)
        let model = ModelEntity(mesh: textMesh, materials: [textMaterial])
        // Move text geometry to the left so that its local origin is in the center
        model.position.x -= model.visualBounds(relativeTo: nil).extents.x / 2
        // Add model to cache
        modelsForClassification[classification] = model
        return model
    }
    
    private func generateObject(anchor: AnchorEntity) {
        let modelEntity = viewModel.getModelEntity(.cup)
        
        let anchor = AnchorEntity(.plane(.any, classification: .any, minimumBounds: .one))
        anchor.addChild(modelEntity)
        arView.installGestures(.all, for: modelEntity)
        arView.scene.anchors.append(anchor)
    }
    
    //MARK: - UIMethods
    private func setupUI() {
        view.addSubview(arView)
        arView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        let scanningDebugLabel = getUITitle(title: "라이다센서 디버깅")
        
        let scanningDebugStack = UIStackView(arrangedSubviews: [scanningDebugLabel, scanningDebugToggle])
        scanningDebugStack.alignment = .center
        scanningDebugStack.axis = .horizontal
        scanningDebugStack.spacing = 15
        scanningDebugStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        scanningDebugStack.isLayoutMarginsRelativeArrangement = true
        
        let yStack = UIStackView(arrangedSubviews: [scanningDebugStack])
        yStack.axis = .vertical
        yStack.spacing = 15
        view.addSubview(yStack)
        yStack.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(10)
            $0.height.equalTo(50)
            yStack.backgroundColor = .black.withAlphaComponent(0.4)
            yStack.layer.cornerRadius = 50 / 2
            yStack.clipsToBounds = true
        }
        
        view.addSubview(debugView)
        debugView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(200)
        }
    }
    
    private func getUIButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.6)
        button.tintColor = .white
        return button
    }
    
    private func getUITitle(title: String) -> UILabel {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.text = title
        label.textColor = .white
        return label
    }
    
}

extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let currentFrame = session.currentFrame {
            viewModel.processARCamera(currentFrame: currentFrame)
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // Remove the ModelEntity for this ARPlaneAnchor
                planeEntities[planeAnchor]?.removeFromParent()
                planeEntities.removeValue(forKey: planeAnchor)
            }
        }
    }
}
