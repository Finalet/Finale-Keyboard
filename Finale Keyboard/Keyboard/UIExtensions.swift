//
//  UIViewExtension.swift
//  Keyboard
//
//  Created by Grant Oganan on 2/1/22.
//

import UIKit
import Foundation

extension UIColor {
    static let clearInteractable = UIColor(red: 1, green: 1, blue: 1, alpha: 0.001)
    static let systemPrimary = UIView().traitCollection.userInterfaceStyle == .light ? UIColor.black : UIColor.white
}

extension Dictionary where Value: Equatable {
    func key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
}

