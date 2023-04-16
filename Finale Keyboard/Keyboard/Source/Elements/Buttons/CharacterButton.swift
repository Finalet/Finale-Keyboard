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
    
    var shortcutPreviewLabel: UILabel?
    
    let calloutView = UIView()
    var calloutYConstraint: NSLayoutConstraint?
    var calloutWidthConstraint: NSLayoutConstraint?
    var calloutXConstraint: NSLayoutConstraint?
    
    let character: String
    
    init(_ character: String) {
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
        calloutWidthConstraint = calloutView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.05)
        calloutWidthConstraint?.isActive = true
        
        titleLabel.font = UIFont(name: "Gilroy-Medium", size: 20)
        titleLabel.text = String(character)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel, anchors: [.leading(0), .trailing(0), .centerX(0)])
        titleYConstraint = titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleYConstraint?.isActive = true
        
        ToggleCapitalization(FinaleKeyboard.instance.shouldCapitalize)
    }
    
    override func OnTapBegin(_ sender: UILongPressGestureRecognizer) {}
    
    override func OnTapChanged(_ sender: UILongPressGestureRecognizer) {
        if didLongPress {
            FinaleKeyboard.instance.MoveCursor(touchLocation: sender.location(in: FinaleKeyboard.instance.view))
        }
    }
    
    override func OnTapEnded(_ sender: UILongPressGestureRecognizer) {
        if didLongPress {
            FinaleKeyboard.instance.EndMoveCursor()
            return
        }
        
        FinaleKeyboard.instance.TypeCharacter(character)
    }
    
    override func OnSwipe(direction: KeyboardButton.SwipeDirection) {
        if direction == .Right {
            FinaleKeyboard.instance.SwipeRight()
        } else if direction == .Left {
            FinaleKeyboard.instance.Delete()
        } else if direction == .Up {
            FinaleKeyboard.instance.SwipeUp()
        } else if direction == .Down {
            if !TypeShortcut() { FinaleKeyboard.instance.SwipeDown() }
        }
    }
    
    override func OnSwipeHoldRepeating(direction: KeyboardButton.SwipeDirection) {
        if direction == .Left {
            FinaleKeyboard.instance.Delete()
            FinaleKeyboard.instance.MiddleRowReactAnimation()
            HapticFeedback.GestureImpactOccurred()
        } else if direction == .Down {
            TypeShortcut()
        }
    }
    
    override func OnLongPress(_ sender: UILongPressGestureRecognizer) {
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
            calloutWidthConstraint?.constant = self.frame.width
        } else {
            calloutYConstraint?.constant = 0
        }
        
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .allowUserInteraction) { [self] in
            calloutView.alpha = 0
            self.layoutIfNeeded()
        }
    }
    
    func ToggleCapitalization (_ inOn: Bool) {
        titleLabel.text = inOn ? titleLabel.text?.capitalized : titleLabel.text?.lowercased()
    }
    
    func ShowShortcutPreview () {
        if let shortcut = FinaleKeyboard.instance.shortcuts[String(character)] {
            shortcutPreviewLabel = UILabel()
            shortcutPreviewLabel?.text = shortcut
            shortcutPreviewLabel?.font = titleLabel.font.withSize(titleLabel.font.pointSize * (shortcut.isEmoji ? 1 : 0.8))
            shortcutPreviewLabel?.textAlignment = .center
            shortcutPreviewLabel?.alpha = 0
            shortcutPreviewLabel?.layer.shadowOffset = .zero
            shortcutPreviewLabel?.layer.shadowOpacity = 0.3
            shortcutPreviewLabel?.layer.shadowRadius = 5
            self.addSubview(shortcutPreviewLabel!, anchors: LayoutAnchor.fullFrame)
        }
        UIView.animate(withDuration: 0.25) { [self] in
            titleLabel.alpha = 0.5
            shortcutPreviewLabel?.alpha = 1
        }
    }
    
    func HideShortcutPreview () {
        UIView.animate(withDuration: 0.25) { [self] in
            titleLabel.alpha = 1
            shortcutPreviewLabel?.alpha = 0
        } completion: { [self] _ in
            shortcutPreviewLabel?.removeFromSuperview()
            shortcutPreviewLabel = nil
        }
    }
    
    @discardableResult
    func TypeShortcut () -> Bool {
        if let shortcut = FinaleKeyboard.instance.shortcuts[String(character)] {
            if shortcut.isEmoji { FinaleKeyboard.instance.TypeEmoji(emoji: shortcut) }
            else { FinaleKeyboard.instance.TypeCharacter(shortcut) }
            AnimateShortcutCallout(title: shortcut)
            HapticFeedback.TypingImpactOccurred()
            return true
        }
        return false
    }
    
    func AnimateShortcutCallout (title: String) {
        let width = title.size(withAttributes: [.font:titleLabel.font!]).width
        
        let label = UILabel(frame: CGRect(x: 0.5*(self.frame.width-width), y: 0, width: width, height: self.frame.height))
        label.text = title
        label.font = titleLabel.font.withSize(titleLabel.font.pointSize * (title.isEmoji ? 1 : 0.8))
        label.textAlignment = .center
        label.textColor = .label
        self.addSubview(label)
        UIView.animate(withDuration: 0.25, delay: 0.25) {
            label.alpha = 0
        }
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
            label.frame.origin.y -= self.frame.height*0.7
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
}
