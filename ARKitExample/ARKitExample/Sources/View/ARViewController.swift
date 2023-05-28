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
    init(ip: String, port: Int32) {
        viewModel = ARViewModel(ip: ip, port: port)
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
                self?.generateObject()
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
    
    //MARK: - AR Method
    private func setupRealityKit() {
        arView.session.run(viewModel.setupARConfiguration())
        arView.addCoaching()
        arView.setupTouch()
    }
    
    private func generateObject() {
        arView.session.delegate = self
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
