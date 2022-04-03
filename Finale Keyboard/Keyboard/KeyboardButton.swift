//
//  ButtonView.swift
//  Keyboard
//
//  Created by Grant Oganan on 2/1/22.
//

import Foundation
import UIKit

class KeyboardButton: UIButton {
    
    var viewController: KeyboardViewController?
    
    var action: KeyboardViewController.Action = KeyboardViewController.Action(type: .Character, title: "")
    
    public var calloutView = UIView()
    public var calloutLabel = UILabel()
    public var calloutImage = UIImageView()
    
    let mainColor = UIColor.gray
    
    var calloutWidth: CGFloat = 0
    var calloutHeight: CGFloat = 0
    
    var registerSwipeSensitivity = 0.5
    var registeredSwipe = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clearInteractable
        
        titleLabel!.font = UIFont(name: "Gilroy-Medium", size: 20)
        
        calloutWidth = frame.height * 0.75
        calloutHeight = calloutWidth * 1.1
        
        calloutView = UIView(frame: CGRect(x: (frame.width - calloutWidth)*0.5, y: (frame.height - calloutHeight)*0.5 , width: calloutWidth, height: calloutHeight))
        calloutView.backgroundColor = mainColor.withAlphaComponent(0)
        calloutView.layer.cornerRadius = 5
        calloutView.isUserInteractionEnabled = false
        
        calloutLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        calloutLabel.textAlignment = .center
        calloutLabel.isUserInteractionEnabled = false
        calloutLabel.font = titleLabel!.font
        
        self.addSubview(calloutLabel)
        self.addSubview(calloutView)
        
        self.bringSubviewToFront(calloutLabel)
    }
    
    func SetupButton () {
        setTitle(action.actionTitle, for: .normal)
        setTitleColor(.systemPrimary, for: .normal)
        calloutLabel.text = titleLabel!.text
        calloutLabel.textColor = titleLabel?.textColor.withAlphaComponent(0)
        
        if (action.actionType == .Function) {
            setImage(getFunctionActionIcon(function: action.functionType), for: .normal)
            imageView?.tintColor = .systemGray
            self.bringSubviewToFront(imageView!)
        }
        
        let touch = UILongPressGestureRecognizer(target: self, action: #selector(RegisterPress))
        touch.minimumPressDuration = 0
        self.addGestureRecognizer(touch)
    }
    
    @objc func RegisterPress (gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began) {
            ShowCallout()
            if action.functionType == .Backspace { viewController?.LongPressDelete(backspace: true) }
            else if action.actionType == .Character { viewController?.LongPressCharacter(touchLocation: gesture.location(in: viewController?.view), button: self) }
            else if action.functionType == .Shift { viewController?.LongPressShift(button: self) }
        } else if (gesture.state != .began && gesture.state != .ended) {
            if (viewController!.toggledAC) {return}
            
            if (!KeyboardViewController.isMovingCursor) {
                EvaluateSwipes(touchLocation: gesture.location(in: self))
            } else {
                viewController?.CheckMoveCursor(touchLocation: gesture.location(in: viewController?.view))
            }
        } else if (gesture.state == .ended) {
            viewController?.CancelWaitingForLongPress()
            if (!registeredSwipe && !viewController!.toggledAC && !KeyboardViewController.isMovingCursor) {
                viewController?.UseAction(action: action)
                HideCallout()
            }
            if KeyboardViewController.isLongPressing { viewController?.CancelLongPress() }
            registeredSwipe = false
        }
    }
    
    func EvaluateSwipes (touchLocation: CGPoint) {
        if registeredSwipe { return }
        
        if (touchLocation.x > frame.size.width + frame.size.width * (1-registerSwipeSensitivity)) { //Swipe right
            registeredSwipe = true
            if action.actionType == .Character { viewController?.SwipeRight() }
            else if action.functionType == .Shift { viewController?.ToggleSymbolsView() }
            else if action.functionType == .SymbolsShift || action.functionType == .ExtraSymbolsShift { viewController?.ToggleSymbolsView() }
            HideCallout(swipeDir: 1)
            viewController?.MiddleRowReactAnimation()
            viewController?.CancelLongPress()
        } else if (touchLocation.x < 0 - frame.size.width * (1-registerSwipeSensitivity)) { //Swipe left
            viewController?.CancelLongPress()
            registeredSwipe = true
            if action.actionType == .Character { viewController?.Delete(); viewController?.LongPressDelete(backspace: false) }
            else if action.functionType == .Backspace { KeyboardViewController.currentViewType == .SearchEmoji ? viewController?.BackAction() : viewController?.ToggleEmojiView() }
            HideCallout(swipeDir: -1)
            if action.actionType != .Character { viewController?.MiddleRowReactAnimation() }
        } else if (touchLocation.y > frame.size.height + frame.size.height * (1-registerSwipeSensitivity)) { //Swipe down
            registeredSwipe = true
            if action.actionType == .Character { viewController?.SwipeDown() }
            HideCallout()
            viewController?.MiddleRowReactAnimation()
            viewController?.CancelLongPress()
        } else if (touchLocation.y < 0 - frame.size.height * (1-registerSwipeSensitivity)) { //Swipe up
            registeredSwipe = true
            if action.actionType == .Character { viewController?.SwipeUp() }
            else if action.functionType == .Shift { viewController?.ToggleLocale() }
            else if action.functionType == .Backspace { KeyboardViewController.currentViewType == .SearchEmoji ? viewController?.BackAction() : viewController?.ReturnAction() }
            HideCallout()
            viewController?.MiddleRowReactAnimation()
            viewController?.CancelLongPress()
        }
    }
    
    func ShowCallout () {
        if action.actionType == .Character {
            ShowCharacterCallout()
        } else if action.actionType == .Function {
            ShowFunctionCallout()
        }
    }
    func ShowCharacterCallout() {
        calloutLabel.textColor = calloutLabel.textColor.withAlphaComponent(1)
        setTitleColor(.clear, for: .normal)
        let y = self.frame.height * 0.5
        self.calloutView.backgroundColor = self.mainColor.withAlphaComponent(0.6)
        self.calloutView.frame.origin.y -= y
        self.calloutLabel.frame.origin.y -= y
        self.calloutImage.frame.origin.y -= y
    }
    func ShowFunctionCallout() {
        calloutView.backgroundColor = self.mainColor.withAlphaComponent(0.6)
        imageView?.tintColor = .systemPrimary
    }

    func HideCharacterCallout(swipeDir: Int) {
        if !isCalloutShown() { return }
        
        let y = self.frame.height * 0.5
        UIView.animate(withDuration: 0.26, delay: 0, options: .allowUserInteraction) {
            self.calloutView.backgroundColor = self.mainColor.withAlphaComponent(0)
            self.calloutLabel.frame.origin.y += y
            if swipeDir == 0 {
                self.calloutView.frame.origin.y += y
            }
        } completion: {_ in
            self.setTitleColor(.systemPrimary, for: .normal)
            self.calloutLabel.textColor = self.calloutLabel.textColor.withAlphaComponent(0)
            self.calloutImage.tintColor = self.calloutImage.tintColor.withAlphaComponent(0)
            if swipeDir != 0 {
                self.calloutView.frame.origin.y += y
            }
        }
        
        if (swipeDir == 0) { return }
        
        UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            if swipeDir == -1 {
                self.calloutView.frame.size.width += self.frame.width*0.7
                self.calloutView.frame.origin.x -= self.frame.width*0.7
                self.calloutView.frame.origin.x -= self.frame.width*0.5
            } else if swipeDir == 1 {
                self.calloutView.frame.size.width += self.frame.width*0.7
                self.calloutView.frame.origin.x += self.frame.width*0.5
            }
        } completion: { _ in
            self.calloutView.frame.size.width = self.calloutWidth
            self.calloutView.frame.origin.x = (self.frame.width - self.calloutWidth)*0.5
        }
    }
    func HideCallout (swipeDir: Int = 0) {
        if action.actionType == .Character {
            HideCharacterCallout(swipeDir: swipeDir)
        } else if action.actionType == .Function {
            HideFunctionCallout()
        }
    }
    func HideFunctionCallout () {
        if action.functionType == .Shift {
            imageView?.tintColor = KeyboardViewController.ShouldCapitalize() ? .systemPrimary : .gray
            if KeyboardViewController.currentViewType == .Characters { setImage(getFunctionActionIcon(function: KeyboardViewController.isCaps ? .Caps : .Shift), for: .normal) }
            else if KeyboardViewController.currentViewType == .Symbols { setImage(getFunctionActionIcon(function: .SymbolsShift), for: .normal) }
            else if KeyboardViewController.currentViewType == .ExtraSymbols { setImage(getFunctionActionIcon(function: .SymbolsShift), for: .normal) }
        } else {
            imageView?.tintColor = .gray
        }
        calloutView.backgroundColor = self.mainColor.withAlphaComponent(0)
    }
    
    func isCalloutShown() -> Bool {
        return (calloutView.backgroundColor?.cgColor.alpha)! > 0.1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getFunctionActionIcon (function: KeyboardViewController.FunctionType) -> UIImage {
        switch function {
        case .Shift:
            return UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(weight: .black))!
        case .SymbolsShift:
            return UIImage(systemName: "character.textbox", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))!
        case .ExtraSymbolsShift:
            return UIImage(systemName: "123.rectangle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))!
        case .Caps:
            return UIImage(systemName: "arrow.up.to.line", withConfiguration: UIImage.SymbolConfiguration(weight: .black))!
        case .Backspace:
            return UIImage(systemName: "delete.left.fill")!
        case .Back:
            return UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))!
        case .none:
            return UIImage(systemName: "exclamationmark.triangle")!
        }
    }
}
