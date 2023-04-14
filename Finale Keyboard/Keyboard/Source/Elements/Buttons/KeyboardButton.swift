//
//  KeyboardButton.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/14/23.
//

import Foundation
import UIKit

class KeyboardButton: UIView {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var registerSwipeSensitivity = 0.5
    var registeredSwipe = false
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clearInteractable
        
        let touch = UILongPressGestureRecognizer(target: self, action: #selector(Touch))
        touch.minimumPressDuration = 0
        self.addGestureRecognizer(touch)
    }
    
    @objc func Touch (_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            ShowCallout()
            OnTapBegin(sender)
        } else if sender.state == .ended {
            if !registeredSwipe && !FinaleKeyboard.instance.toggledAC && !FinaleKeyboard.isMovingCursor {
                OnTapEnded(sender)
                HideCallout()
            }
            FinaleKeyboard.instance.CancelLongPress()
            
            registeredSwipe = false
        } else {
            if FinaleKeyboard.instance.toggledAC { return }
            
            if FinaleKeyboard.isMovingCursor {
                FinaleKeyboard.instance.MoveCursor(touchLocation: sender.location(in: FinaleKeyboard.instance.view))
            } else {
                EvaluateSwipe(touchLocation: sender.location(in: self))
            }
        }
    }
    
    func EvaluateSwipe (touchLocation: CGPoint) {
        if registeredSwipe { return }
        
        if (touchLocation.x > frame.size.width + frame.size.width * (1-registerSwipeSensitivity)) {
            RegisterSwipe(direction: .Right)
        } else if (touchLocation.x < 0 - frame.size.width * (1-registerSwipeSensitivity)) {
            RegisterSwipe(direction: .Left)
        } else if (touchLocation.y > frame.size.height + frame.size.height * (1-registerSwipeSensitivity)) {
            RegisterSwipe(direction: .Down)
        } else if (touchLocation.y < 0 - frame.size.height * (1-registerSwipeSensitivity)) {
            RegisterSwipe(direction: .Up)
        }
    }
    
    private func RegisterSwipe (direction: SwipeDirection) {
        registeredSwipe = true
        FinaleKeyboard.instance.MiddleRowReactAnimation()
        FinaleKeyboard.instance.CancelLongPress()
        HapticFeedback.GestureImpactOccurred()
        HideCallout(direction: direction)
        OnSwipe(direction: direction)
    }
    
    func OnTapBegin (_ sender: UILongPressGestureRecognizer) {}
    func OnTapEnded (_ sender: UILongPressGestureRecognizer) {}
    
    func OnSwipe (direction: SwipeDirection) {}
    
    func ShowCallout () {}
    func HideCallout (direction: SwipeDirection? = nil) {}
    
    
    enum SwipeDirection {
        case Left
        case Right
        case Up
        case Down
    }
}
