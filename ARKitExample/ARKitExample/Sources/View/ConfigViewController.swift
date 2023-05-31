//
//  ConfigViewController.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import UIKit
import RxCocoa
import RxSwift

class ConfigViewController: UIViewController {
    //MARK: - UserDefaultsKey
    enum ConfigKeys {
        static let ip = "ip"
        static let port = "port"
    }
    
    enum ButtonType {
        case confirm
        case debug
    }
    
    //MARK: -  Properties
    let disposeBag = DisposeBag()
    lazy var ipTextField = getTextField()
    lazy var portTextField = getTextField()
    
    lazy var confirmButton = getActionButton(title: "완료")
    lazy var debugButton = getActionButton(title: "위 PORT에서 데이터 수신")
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureInitialData()
        bind()
    }
    
    //MARK: - Bind
    private func bind() {
        confirmButton.rx.tap
            .subscribe { [weak self] _ in
                self?.buttonTapped(type: .confirm)
            }
            .disposed(by: disposeBag)
        
        debugButton.rx.tap
            .subscribe { [weak self] _ in
                self?.buttonTapped(type: .debug)
            }
            .disposed(by: disposeBag)
    }
    
    //MARK: - Methods
    private func setupUI() {
        let ipStack = UIStackView(arrangedSubviews: [getInfoLabel("IP"), ipTextField])
        let portStack = UIStackView(arrangedSubviews: [getInfoLabel("PORT"), portTextField])
        [ipStack, portStack].forEach { $0.axis = .horizontal; $0.spacing = 10; }
        let yStack = UIStackView(arrangedSubviews: [ipStack, portStack, confirmButton, debugButton])
        yStack.axis = .vertical
        yStack.spacing = 30
        
        view.addSubview(yStack)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            yStack.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(60)
                $0.centerY.equalToSuperview()
            }
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            yStack.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(200)
                $0.centerY.equalToSuperview()
            }
        }
    }
    
    private func getInfoLabel(_ string: String) -> UILabel {
        let label = UILabel()
        label.text = string
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 16)
        label.widthAnchor.constraint(equalToConstant: 60).isActive = true
        return label
    }
    
    private func getTextField() -> UITextField {
        let tf = UITextField()
        tf.backgroundColor = .darkGray
        tf.textAlignment = .center
        tf.keyboardType = .decimalPad
        tf.heightAnchor.constraint(equalToConstant: 35).isActive = true
        tf.layer.cornerRadius = 35 / 2
        tf.textColor = .white
        tf.clipsToBounds = true
        return tf
    }
    
    private func getActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemIndigo
        button.heightAnchor.constraint(equalToConstant: 35).isActive = true
        button.layer.cornerRadius = 35 / 2
        button.clipsToBounds = true
        return button
    }
    
    private func configureInitialData() {
        guard let ip = UserDefaults.standard.string(forKey: ConfigKeys.ip),
              let port = UserDefaults.standard.string(forKey: ConfigKeys.port) else { return }
        ipTextField.text = ip
        portTextField.text = port
    }
    
    private func buttonTapped(type: ButtonType) {
        guard let ip = ipTextField.text,
              let port = portTextField.text else { return }
        if !ip.isEmpty && !port.isEmpty && ip.count > 8 && Int32(port) != nil {
            guard let port = Int32(port) else { return }
            UserDefaults.standard.set(ip, forKey: ConfigKeys.ip)
            UserDefaults.standard.set(String(port), forKey: ConfigKeys.port)
            pushNextViewController(ip: ip, port: port, type: type)
        }
    }
    
    private func pushNextViewController(ip: String, port: Int32, type: ButtonType) {
        DispatchQueue.main.async { [weak self] in
            switch type {
            case .confirm:
                let viewModel = ARViewModel(ip: ip, port: port)
                let vc = ARViewController(viewModel: viewModel)
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: true)
            case .debug:
                let vc = DebugViewController(ip: ip, port: port)
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: true)
            }
        }
    }
}
