//
//  CharacterButton.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/14/23.
//

import Foundation
import UIKit

class CharacterButton: KeyboardButton {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let titleLabel = UILabel()
    var titleYConstraint: NSLayoutConstraint?
    
    let calloutView = UIView()
    var calloutYConstraint: NSLayoutConstraint?
    var calloutWidthConstraint: NSLayoutConstraint?
    var calloutXConstraint: NSLayoutConstraint?
    
    let character: Character
    
    init(_ character: Character) {
        self.character = character
        super.init()
        
        calloutView.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        calloutView.layer.cornerRadius = 5
        calloutView.alpha = 0
        self.addSubview(calloutView, anchors: [.heightMultiplier(0.8)])
        calloutYConstraint = calloutView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        calloutYConstraint?.isActive = true
        calloutXConstraint = calloutView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        calloutXConstraint?.isActive = true
        calloutWidthConstraint = calloutView.widthAnchor.constraint(equalTo: self.widthAnchor)
        calloutWidthConstraint?.isActive = true
        
        titleLabel.font = UIFont(name: "Gilroy-Medium", size: 20)
        titleLabel.text = String(character)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel, anchors: [.leading(0), .trailing(0), .centerX(0)])
        titleYConstraint = titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleYConstraint?.isActive = true
    }
    
    override func OnTapBegin(_ sender: UILongPressGestureRecognizer) {}
    
    override func OnTapChanged(_ sender: UILongPressGestureRecognizer) {
        if didLongPressSucceed {
            FinaleKeyboard.instance.MoveCursor(touchLocation: sender.location(in: FinaleKeyboard.instance.view))
        } else {
            EvaluateSwipe(touchLocation: sender.location(in: self))
        }
    }
    
    override func OnTapEnded(_ sender: UILongPressGestureRecognizer) {
        if didLongPressSucceed {
            FinaleKeyboard.instance.EndMoveCursor()
            return
        }
        
        FinaleKeyboard.instance.TypeCharacter(String(character))
    }
    
    override func OnSwipe(direction: KeyboardButton.SwipeDirection) {
        if direction == .Right {
            FinaleKeyboard.instance.SwipeRight()
        } else if direction == .Left {
            FinaleKeyboard.instance.Delete()
        } else if direction == .Up {
            FinaleKeyboard.instance.SwipeUp()
        } else if direction == .Down {
            if !TypeExtraCharacters() { FinaleKeyboard.instance.SwipeDown() }
        }
    }
    
    override func OnLongPressSuccess(_ sender: UILongPressGestureRecognizer) {
        FinaleKeyboard.instance.StartMoveCursor(touchLocation: sender.location(in: FinaleKeyboard.instance.view))
        self.HideCallout()
    }
    
    override func ShowCallout() {
        calloutView.alpha = 1
        
        titleYConstraint?.constant = -self.frame.height*0.5
        
        calloutYConstraint?.constant = -self.frame.height*0.5
        calloutXConstraint?.constant = 0
        calloutWidthConstraint?.constant = 0
        
        HapticFeedback.TypingImpactOccurred()
    }
    
    override func HideCallout(direction: SwipeDirection? = nil) {
        titleYConstraint?.constant = 0
        
        if let direction = direction, direction == .Left || direction == .Right {
            calloutXConstraint?.constant = self.frame.width*0.7*(direction == .Left ? -1 : 1)
            calloutWidthConstraint?.constant = self.frame.width*1
        } else {
            calloutYConstraint?.constant = 0
        }
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .allowUserInteraction) { [self] in
            calloutView.alpha = 0
            self.layoutIfNeeded()
        }
    }
    
    func TypeExtraCharacters () -> Bool {
        if let secondaryChar = Defaults.secondaryCharacters[character] {
            if secondaryChar.isEmoji { FinaleKeyboard.instance.TypeEmoji(emoji: secondaryChar) }
            else { FinaleKeyboard.instance.TypeCharacter(secondaryChar) }
            return true
        }
        return false
    }
}
