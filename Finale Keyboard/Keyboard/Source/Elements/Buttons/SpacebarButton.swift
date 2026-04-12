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
    
    let iconView = UIImageView()
    
    init () {
        super.init(" ")
        self.titleLabel.removeFromSuperview()

        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(systemName: "space", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
        self.addSubview(iconView, anchors: [.widthMultiplier(1), .widthMultiplier(0.6), .centerX(0)])
        
        titleYConstraint?.isActive = false
        titleYConstraint = iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleYConstraint?.isActive = true
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
