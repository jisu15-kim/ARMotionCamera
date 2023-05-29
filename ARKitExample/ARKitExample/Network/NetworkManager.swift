//
//  NetworkManager.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import Foundation
import Socket

class NetworkManager {
    //MARK: - Properties
    let ip: String
    let port: Int32
    
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
}
