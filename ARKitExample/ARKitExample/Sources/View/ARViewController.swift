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
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eyes.inverse"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.6)
        button.tintColor = .white
        return button
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
        setupRealityKit()
    }
    //MARK: - Bind
    private func bind() {
        button.rx.tap
            .bind { [weak self] _ in
//                self?.generateObject()
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
    
    //MARK: - Selector
    @objc func didTapScreen(_ recognizer: UIGestureRecognizer) {
    
        /// hitTest방식 - 전통적인 방식으로 2D 좌표를 3D로 변환
//        let touchLocation = recognizer.location(in: arView)
//        let hitTestResults = arView.hitTest(touchLocation, types: .estimatedHorizontalPlane)
//        print("touchLocation: \(touchLocation), hitResult: \(hitTestResults)")
//
//        if let hitTestResult = hitTestResults.first {
//            let transform = hitTestResult.worldTransform
//            print("transform: \(transform)")
//            // place the 3D model at the position of the detected plane
//            let anchor = AnchorEntity(world: transform)
//            generateObject(anchor: anchor)
//        }
        
        /// 레이트리이싱방식 - 가상의선의 교차점을 통한 위치 변환
        /// iOS 14 이상
        let touchLocation = recognizer.location(in: arView)
        let results = arView.raycast(from: touchLocation, allowing: .estimatedPlane, alignment: .any)

        if let firstResult = results.first {
            // Use the transform result to create an anchor
            let anchor = AnchorEntity(world: firstResult.worldTransform)
            generateObject(anchor: anchor)
        }
        else {
            print("Raycast did not find any surface")
        }
    }
    
    //MARK: - AR Method
    private func setupRealityKit() {
        arView.session.delegate = self
        arView.session.run(viewModel.setupARConfiguration())
        arView.addCoaching()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapScreen(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func generateObject(anchor: AnchorEntity) {
        let modelEntity = viewModel.getModelEntity(.cup)
        
        let anchor = AnchorEntity(.plane(.any, classification: .any, minimumBounds: .one))
        anchor.addChild(modelEntity)
        arView.installGestures(.all, for: modelEntity)
        arView.scene.anchors.append(anchor)
    }
    
    private func setARCamera() {
        
    }
    
    //MARK: - Methods
    private func setupUI() {
        view.addSubview(arView)
        arView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubview(button)
        button.snp.makeConstraints {
            $0.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(50)
            button.layer.cornerRadius = 50 / 2
            button.clipsToBounds = true
        }
        
        view.addSubview(debugView)
        debugView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(200)
        }
    }
}

extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let currentFrame = session.currentFrame {
            viewModel.processARCamera(currentFrame: currentFrame)
        }
    }
}
