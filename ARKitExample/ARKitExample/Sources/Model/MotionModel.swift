//
//  MotionModel.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import Foundation

struct MotionModel: Codable {
    let position: Position
    let rotation: Rotation
    let quaternion: Quaternion
    
}

struct Position: Codable {
    let x: Float
    let y: Float
    let z: Float
}

struct Rotation: Codable {
    let x: Float
    let y: Float
    let z: Float
}


struct Quaternion: Codable {
    let x: Float
    let y: Float
    let z: Float
    let w: Float
}
