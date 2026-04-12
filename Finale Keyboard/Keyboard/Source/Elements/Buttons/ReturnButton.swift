//
//  ReturnButton.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/11/26.
//

import Foundation
import UIKit

class ReturnButton: CharacterButton {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var function = Function.Return
    let iconView = UIImageView()

    init () {
        super.init("\n")
        self.titleLabel.removeFromSuperview()

        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit
        iconView.image = function.icon
        self.addSubview(iconView, anchors: [.widthMultiplier(1), .widthMultiplier(0.6), .centerX(0)])
        
        titleYConstraint?.isActive = false
        titleYConstraint = iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleYConstraint?.isActive = true
    }
    
    override func OnTapEnded(_ sender: UILongPressGestureRecognizer) {
        function.TapAction()
    }

    override func OnTapChanged(_ sender: UILongPressGestureRecognizer) {}
    override func OnSwipe(direction: KeyboardButton.SwipeDirection) {}
    override func OnLongPress(_ sender: UILongPressGestureRecognizer) {}

    override func OnSwipeHoldRepeating(direction: KeyboardButton.SwipeDirection) {
        if (direction == .Up) {
            function.TapAction()
            HapticFeedback.TypingImpactOccurred()
        }
    }
    
    override func ShowCallout() {
        super.ShowCallout()
        iconView.tintColor = .label
    }
    
    override func HideCallout(direction: KeyboardButton.SwipeDirection? = nil) {
        super.HideCallout(direction: direction)
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .allowUserInteraction) { [self] in
            iconView.tintColor = .systemGray
        }
    }

    func ChangeFunction(new: Function) {
        self.function = new
        iconView.image = function.icon
    }
}
