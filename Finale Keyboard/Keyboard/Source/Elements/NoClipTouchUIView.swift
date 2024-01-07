//
//  KeyboardRow.swift
//  Keyboard
//
//  Created by Grant Oganyan on 1/7/24.
//

import Foundation
import UIKit

class NoClipTouchUIView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let subviews = self.subviews.reversed()
        for member in subviews {
            let subPoint = member.convert(point, from: self)
            if let result: UIView = member.hitTest(subPoint, with:event) {
                return result
            }
        }
        return super.hitTest(point, with: event)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return super.point(inside: point, with: event)
    }
}
