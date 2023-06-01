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
                    // 버퍼 초기화
                    buffer.removeAll(keepingCapacity: true)
                }
            } catch let error {
                print("NetworkReceiveError: \(error)")
            }
        }
    }
}

