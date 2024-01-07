//
//  FinaleKeyboard+DynamicTouchZones.swift
//  Keyboard
//
//  Created by Grant Oganyan on 1/7/24.
//

import Foundation
import UIKit

extension FinaleKeyboard {
    
    func ScaleCharacterKey(key: String, by: CGFloat) {
        if let button = characterButtons[key] {
            button.ScaleTouchZone(by: by)
            if let rowView = button.superview {
                rowView.bringSubviewToFront(button)
                rowView.superview?.bringSubviewToFront(rowView)
            }
        }
    }
    
}
