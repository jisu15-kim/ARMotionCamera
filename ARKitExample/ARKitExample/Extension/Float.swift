//
//  Float.swift
//  ARKitExample
//
//  Created by 김지수 on 2023/05/28.
//

import Foundation

extension Float {
    var formatToSecond: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
