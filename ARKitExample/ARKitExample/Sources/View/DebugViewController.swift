//
//  DebugViewController.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/06/01.
//

import UIKit
import RxSwift

class DebugViewController: UIViewController {
    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let network: NetworkManager
    lazy var label = getLabel()
    
    //MARK: - Lifecycle
    init(ip: String, port: Int32) {
        self.network = NetworkManager(ip: ip, port: port)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        network.receiveData()
        setupUI()
        bind()
    }
    
    //MARK: - Bind
    private func bind() {
        network.debugString
            .bind(onNext: { [weak self] string in
                DispatchQueue.main.async {
                    self?.label.text = string
                }
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Methods
    private func getLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        label.text = "N/A"
        return label
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(label)
        label.snp.makeConstraints {
            $0.centerY.centerX.equalToSuperview()
        }
    }
}
