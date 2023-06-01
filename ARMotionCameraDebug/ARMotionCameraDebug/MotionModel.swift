import Foundation

struct MotionModel: Codable {
    let position: Position
    let quaternion: Quaternion
}

struct Position: Codable {
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
