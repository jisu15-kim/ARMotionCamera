//
//  NetworkManager.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import Foundation
import RxRelay
import Socket

class NetworkManager {
    //MARK: - Properties
    let ip: String
    let port: Int32
    let debugString = PublishRelay<String>()
    
    //MARK: - Lifecycle
    init(ip: String, port: Int32) {
        self.ip = ip
        self.port = port
    }
    
    //MARK: - Methods
    func sendBinaryData(motionData: MotionModel) {
        var getMotionData = motionData
        var binaryData = Data()
        let mutableData = withUnsafeMutableBytes(of: &getMotionData) { data in
            Data(data)
        }
        binaryData.append(mutableData)
        
        // 소켓 생성
        let socket = try! Socket.create(family: .inet, type: .datagram, proto: .udp)

        // UDP 주소 생성 (전송할 호스트와 포트 번호를 설정)
        let address = Socket.createAddress(for: ip, on: port)

        // 데이터 전송
        if let dataSend = try? socket.write(from: binaryData, to: address!) {
//            print("Sent \(dataSend) bytes")
        } else {
            print("데이터 전송 오류")
        }
    }
    
    func receiveData() {
        DispatchQueue.global().async { [weak self] in

            do {
                // UDP 소켓 생성
                let socket = try Socket.create(family: .inet, type: .datagram, proto: .udp)

                // 주소와 포트를 바인딩
                guard let port = self?.port else { return }
                try socket.listen(on: Int(port))
                print("UDP 소켓이 포트 \(port)에서 수신 대기중.")

                // 데이터 수신
                var buffer = Data(capacity: 1024)
                
                while true {
                    let (_, _) = try! socket.readDatagram(into: &buffer)
                    
                    if let motionModel = self?.binaryDataDecoding(withMotionModelData: buffer) {
                        self?.debugString.accept("X: \(motionModel.position.x) ⎮ Y: \(motionModel.position.y) ⎮ Z: \(motionModel.position.z)")
                    }
                    
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
