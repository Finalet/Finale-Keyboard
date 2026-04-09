//
//  SpacebarButton.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/8/26.
//

import Foundation
import UIKit

class SpacebarButton: CharacterButton {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init () {
        super.init(" ")
        self.titleLabel.text = "⎵"
    }
    
    override func OnSwipe(direction: KeyboardButton.SwipeDirection) {
        if (direction == .Left || direction == .Right) {
            FinaleKeyboard.instance.ToggleLocale()
        }
    }
    
    override func OnSwipeHoldRepeating(direction: KeyboardButton.SwipeDirection) {
        if (direction == .Up) {
            TypeCharacter(withDownCallout: true)
            HapticFeedback.TypingImpactOccurred()
        }
    }
}
