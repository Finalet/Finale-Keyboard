//
//  HapticFeedback.swift
//  Keyboard
//
//  Created by Grant Oganyan on 6/8/22.
//

import Foundation
import UIKit

class HapticFeedback {
    static var lastImpactTime: Double = 0
    static var typingDelay = 0.05
    static var gestureDelay = 0.1
    
    static func TypingImpactOccurred() {
        if !FinaleKeyboard.isTypingHapticEnabled { return }
        
        if Date().timeIntervalSinceReferenceDate - lastImpactTime > typingDelay {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            lastImpactTime = Date().timeIntervalSinceReferenceDate
        }
    }
    
    static func GestureImpactOccurred() {
        if !FinaleKeyboard.isGesturesHapticEnabled { return }
        
        if Date().timeIntervalSinceReferenceDate - lastImpactTime > gestureDelay {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            lastImpactTime = Date().timeIntervalSinceReferenceDate
        }
    }
}
