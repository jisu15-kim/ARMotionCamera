//
//  ViewController.swift
//  ARMotionCameraDebug
//
//  Created by 김지수 on 2023/06/01.
//

import Cocoa
import SnapKit
import Socket

class ViewController: NSViewController {
    
    @IBOutlet weak var debugLabel: NSTextFieldCell!
    @IBOutlet weak var portTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        print("ButtonTapped")
        
        if portTextField != nil && Int(portTextField.stringValue) != nil {
            let port = Int(portTextField.stringValue)!
            receiveData(port: port)
            
        } else {
            debugLabel.stringValue = "Wrong Port"
        }
    }
    
    func receiveData(port: Int) {
        DispatchQueue.global().async { [weak self] in

            do {
                // UDP 소켓 생성
                let socket = try Socket.create(family: .inet, type: .datagram, proto: .udp)

                // 주소와 포트를 바인딩
                try socket.listen(on: Int(port))
                print("UDP 소켓이 포트 \(port)에서 수신 대기중.")

                // 데이터 수신
                var buffer = Data(capacity: 1024)
                
                while true {
                    let (_, _) = try! socket.readDatagram(into: &buffer)
                    
                    guard let receiveString = String(data: buffer, encoding: .utf8) else { return }
                    DispatchQueue.main.async { [weak self] in
                        self?.debugLabel.stringValue = receiveString
                    }
                    
//                    if let motionModel = self?.binaryDataDecoding(withMotionModelData: buffer) {
//                        DispatchQueue.main.async {
//                            self?.debugLabel.stringValue =
//                            ("X: \(motionModel.position.x) ⎮ Y: \(motionModel.position.y) ⎮ Z: \(motionModel.position.z)")
//                        }
//                    }
                    
                    // 버퍼 초기화
                    buffer.removeAll(keepingCapacity: true)
                }
            } catch let error {
                print("NetworkReceiveError: \(error)")
            }
        }
    }
    
    func binaryDataDecoding(withMotionModelData data: Data) -> MotionModel {
        
        /// 1. data의 앞에서 12바이트 가져오기
        /// 2. Float 바이트(4) 만큼 가져오기
        /// 3. .advanced(by: 4) - 4바이트 옆으로 이동한 뒤에 가져오기
        /// 에러처리 해줘야댐
        
        let positionBytes = data.prefix(12)
        let positionX = positionBytes.withUnsafeBytes { $0.load(as: Float.self) }
        let positionY = positionBytes.advanced(by: 4).withUnsafeBytes { $0.load(as: Float.self) }
        let positionZ = positionBytes.advanced(by: 8).withUnsafeBytes { $0.load(as: Float.self) }
        
        let quaternionBytes = data.suffix(16)
        let quaternionX = quaternionBytes.withUnsafeBytes { $0.load(as: Float.self) }
        let quaternionY = quaternionBytes.advanced(by: 4).withUnsafeBytes { $0.load(as: Float.self) }
        let quaternionZ = quaternionBytes.advanced(by: 8).withUnsafeBytes { $0.load(as: Float.self) }
        let quaternionW = quaternionBytes.advanced(by: 12).withUnsafeBytes { $0.load(as: Float.self) }
        
        let positionModel = Position(x: positionX, y: positionY, z: positionZ)
        let quaternionModel = Quaternion(x: quaternionX, y: quaternionY, z: quaternionZ, w: quaternionW)
        
        return MotionModel(position: positionModel, quaternion: quaternionModel)
    }
}

