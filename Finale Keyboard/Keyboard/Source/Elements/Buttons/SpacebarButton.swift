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
        self.titleLabel.font = UIFont.systemFont(ofSize: 32)
        self.titleLabel.transform = CGAffineTransform(translationX: 0, y: -6)
    }
    
    override func OnTapEnded(_ sender: UILongPressGestureRecognizer) {
        if (!FinaleKeyboard.isSpacebarAutocorrectOn || didLongPress) {
            return super.OnTapEnded(sender)
        }

        FinaleKeyboard.instance.SwipeRight()
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
