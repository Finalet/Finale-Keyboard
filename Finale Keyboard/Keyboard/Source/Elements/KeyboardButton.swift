//
//  ButtonView.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/1/22.
//

import Foundation
import UIKit

class KeyboardButton: UIView {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let action: Action
    
    let titleLabel = UILabel()
    var titleYConstraint: NSLayoutConstraint?
    
    let iconView = UIImageView()
    
    let calloutView = UIView()
    var calloutYConstraint: NSLayoutConstraint?
    var calloutWidthConstraint: NSLayoutConstraint?
    var calloutXConstraint: NSLayoutConstraint?
    
    var registerSwipeSensitivity = 0.5
    var registeredSwipe = false
    
    init(action: Action) {
        self.action = action
        super.init(frame: .zero)
        
        self.backgroundColor = .clearInteractable
        
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
        titleLabel.text = action.actionTitle
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel, anchors: [.leading(0), .trailing(0), .centerX(0)])
        titleYConstraint = titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        titleYConstraint?.isActive = true
        
        iconView.image = action.functionType.icon
        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit
        self.addSubview(iconView, anchors: [.widthMultiplier(1), .widthMultiplier(0.5), .centerY(0), .centerX(0)])
        
        let touch = UILongPressGestureRecognizer(target: self, action: #selector(RegisterPress))
        touch.minimumPressDuration = 0
        self.addGestureRecognizer(touch)
    }
    
    @objc func RegisterPress (gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began) {
            ShowCallout()
            if action.functionType == .Backspace { FinaleKeyboard.instance.LongPressDelete(backspace: true) }
            else if action.actionType == .Character { FinaleKeyboard.instance.LongPressCharacter(touchLocation: gesture.location(in: FinaleKeyboard.instance.view), button: self) }
            else if action.functionType == .Shift { FinaleKeyboard.instance.LongPressShift(button: self) }
            
            if action.actionType == .Character { HapticFeedback.TypingImpactOccurred() }
        } else if (gesture.state != .began && gesture.state != .ended) {
            if (FinaleKeyboard.instance.toggledAC) {return}
            
            if (!FinaleKeyboard.isMovingCursor) {
                EvaluateSwipes(touchLocation: gesture.location(in: self))
            } else {
                FinaleKeyboard.instance.CheckMoveCursor(touchLocation: gesture.location(in: FinaleKeyboard.instance.view))
            }
        } else if (gesture.state == .ended) {
            FinaleKeyboard.instance.CancelWaitingForLongPress()
            if (!registeredSwipe && !FinaleKeyboard.instance.toggledAC && !FinaleKeyboard.isMovingCursor) {
                FinaleKeyboard.instance.UseAction(action: action)
                HideCallout()
            }
            if FinaleKeyboard.isLongPressing { FinaleKeyboard.instance.CancelLongPress() }
            registeredSwipe = false
        }
    }
    
    func EvaluateSwipes (touchLocation: CGPoint) {
        if registeredSwipe { return }
        
        if (touchLocation.x > frame.size.width + frame.size.width * (1-registerSwipeSensitivity)) { //Swipe right
            registeredSwipe = true
            if action.actionType == .Character { FinaleKeyboard.instance.SwipeRight() }
            else if action.functionType == .Shift { FinaleKeyboard.instance.ToggleSymbolsView() }
            else if action.functionType == .SymbolsShift || action.functionType == .ExtraSymbolsShift { FinaleKeyboard.instance.ToggleSymbolsView() }
            HideCallout(swipeDir: .Right)
            FinaleKeyboard.instance.MiddleRowReactAnimation()
            FinaleKeyboard.instance.CancelLongPress()
            
            HapticFeedback.GestureImpactOccurred()
        } else if (touchLocation.x < 0 - frame.size.width * (1-registerSwipeSensitivity)) { //Swipe left
            FinaleKeyboard.instance.CancelLongPress()
            registeredSwipe = true
            if action.actionType == .Character { FinaleKeyboard.instance.Delete(); FinaleKeyboard.instance.LongPressDelete(backspace: false) }
            else if action.functionType == .Backspace { FinaleKeyboard.currentViewType == .SearchEmoji ? FinaleKeyboard.instance.BackAction() : FinaleKeyboard.instance.OpenEmoji() }
            HideCallout(swipeDir: .Left)
            if action.actionType != .Character { FinaleKeyboard.instance.MiddleRowReactAnimation() }
            
            HapticFeedback.GestureImpactOccurred()
        } else if (touchLocation.y > frame.size.height + frame.size.height * (1-registerSwipeSensitivity)) { //Swipe down
            registeredSwipe = true
            if action.actionType == .Character {
                if !TypeExtraCharacters() { FinaleKeyboard.instance.SwipeDown() }
            }
            HideCallout()
            FinaleKeyboard.instance.MiddleRowReactAnimation()
            FinaleKeyboard.instance.CancelLongPress()
            
            HapticFeedback.GestureImpactOccurred()
        } else if (touchLocation.y < 0 - frame.size.height * (1-registerSwipeSensitivity)) { //Swipe up
            registeredSwipe = true
            if action.actionType == .Character { FinaleKeyboard.instance.SwipeUp() }
            else if action.functionType == .Shift { FinaleKeyboard.instance.ToggleLocale() }
            else if action.functionType == .Backspace { FinaleKeyboard.currentViewType == .SearchEmoji ? FinaleKeyboard.instance.BackAction() : FinaleKeyboard.instance.ReturnAction() }
            HideCallout()
            FinaleKeyboard.instance.MiddleRowReactAnimation()
            FinaleKeyboard.instance.CancelLongPress()
            
            HapticFeedback.GestureImpactOccurred()
        }
        
    }
    
    func TypeExtraCharacters () -> Bool {
        if action.actionTitle == "е" {
            FinaleKeyboard.instance.UseAction(action: .init(type: .Character, title: "ё"))
            return true
        } else if action.actionTitle == "ь" {
            FinaleKeyboard.instance.UseAction(action: .init(type: .Character, title: "ъ"))
            return true
        }
        return false
    }
    
    func ShowCallout () {
        if action.actionType == .Character {
            ShowCharacterCallout()
        } else if action.actionType == .Function {
            ShowFunctionCallout()
        }
    }
    func HideCallout (swipeDir: SwipeDirection? = nil) {
        if action.actionType == .Character {
            HideCharacterCallout(swipeDir: swipeDir)
        } else if action.actionType == .Function {
            HideFunctionCallout()
        }
    }
    
    func ShowCharacterCallout() {
        calloutView.alpha = 1
        
        titleYConstraint?.constant = -self.frame.height*0.5
        
        calloutYConstraint?.constant = -self.frame.height*0.5
        calloutXConstraint?.constant = 0
        calloutWidthConstraint?.constant = 0
    }

    func HideCharacterCallout(swipeDir: SwipeDirection? = nil) {
        if !isCalloutShown() { return }
        
        titleYConstraint?.constant = 0
        
        if let swipeDir = swipeDir, swipeDir == .Left || swipeDir == .Right {
            calloutXConstraint?.constant = self.frame.width*0.7*(swipeDir == .Left ? -1 : 1)
            calloutWidthConstraint?.constant = self.frame.width*1
        } else {
            calloutYConstraint?.constant = 0
        }
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .allowUserInteraction) { [self] in
            calloutView.alpha = 0
            self.layoutIfNeeded()
        }
    }
    
    
    func ShowFunctionCallout() {
        calloutView.alpha = 1
        iconView.tintColor = .label
    }
    func HideFunctionCallout () {
        if action.functionType == .Shift {
            iconView.tintColor = FinaleKeyboard.instance.shouldCapitalize ? .label : .gray
            if FinaleKeyboard.currentViewType == .Characters { iconView.image = FinaleKeyboard.isCaps ? FunctionType.Caps.icon : FunctionType.Shift.icon }
            else if FinaleKeyboard.currentViewType == .Symbols { iconView.image = FunctionType.SymbolsShift.icon }
            else if FinaleKeyboard.currentViewType == .ExtraSymbols { iconView.image = FunctionType.ExtraSymbolsShift.icon }
        }
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3) { [self] in
            calloutView.alpha = 0
            iconView.tintColor = action.functionType == .Shift ? (FinaleKeyboard.instance.shouldCapitalize ? .label : .gray) : .gray
        }
    }
    
    func isCalloutShown() -> Bool {
        return (calloutView.backgroundColor?.cgColor.alpha)! > 0.1
    }
    
    enum SwipeDirection {
        case Left
        case Right
        case Up
        case Down
    }
}
