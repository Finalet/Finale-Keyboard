//
//  UIViewExtension.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/1/22.
//

import UIKit
import Foundation

extension UIColor {
    static let clearInteractable = UIColor(red: 1, green: 1, blue: 1, alpha: 0.001)
    static let brand = UIColor(red: 0.33, green: 0.51, blue: 0.85, alpha: 1)
    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
    
    func lerp (second: UIColor, percentage: CGFloat) -> UIColor {
        return UIColor(red: (1-percentage)*self.components.red + percentage*second.components.red, green: (1-percentage)*self.components.green + percentage*second.components.green, blue: (1-percentage)*self.components.blue + percentage*second.components.blue, alpha: (1-percentage)*self.components.alpha + percentage*second.components.alpha)
    }
}

extension Dictionary where Value: Equatable {
    func key(forValue value: Value) -> Key? {
        return first { $0.1 == value }?.0
    }
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
}

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension String {
    
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}
