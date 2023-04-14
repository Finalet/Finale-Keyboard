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
    
    var longPressTimer: Timer?
    var longPressRepeatTimer: Timer?
    let longPressDelay = 0.3
    let longPressRepeatInterval = 0.1
    
    var didLongPress = false
    var didHoldSwipe = false
    
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
            longPressTimer = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { _ in
                self.didLongPress = true
                self.OnLongPress(sender)
                self.longPressRepeatTimer = Timer.scheduledTimer(withTimeInterval: self.longPressRepeatInterval, repeats: true) { _ in
                    self.OnLongPressRepeating(sender)
                }
            }
        } else if sender.state == .ended {
            if !registeredSwipe {
                OnTapEnded(sender)
                HideCallout()
            }
            
            CancelLongPress()
            
            registeredSwipe = false
        } else {
            OnTapChanged(sender)
            if !didLongPress {
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
        HapticFeedback.GestureImpactOccurred()
        CancelLongPress()
        HideCallout(direction: direction)
        OnSwipe(direction: direction)
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { _ in
            self.didHoldSwipe = true
            self.longPressRepeatTimer = Timer.scheduledTimer(withTimeInterval: self.longPressRepeatInterval, repeats: true) { _ in
                self.OnSwipeHoldRepeating(direction: direction)
            }
        }
    }
    
    private func CancelLongPress () {
        didLongPress = false
        longPressTimer?.invalidate()
        longPressRepeatTimer?.invalidate()
    }
    
    func OnTapBegin (_ sender: UILongPressGestureRecognizer) {}
    func OnTapChanged (_ sender: UILongPressGestureRecognizer) {}
    func OnTapEnded (_ sender: UILongPressGestureRecognizer) {}
    
    func OnSwipe (direction: SwipeDirection) {}
    
    func OnLongPress (_ sender: UILongPressGestureRecognizer) {}
    func OnLongPressRepeating (_ sender: UILongPressGestureRecognizer) {}
    
    func OnSwipeHoldRepeating (direction: SwipeDirection) {}
    
    func ShowCallout () {}
    func HideCallout (direction: SwipeDirection? = nil) {}
    
    
    enum SwipeDirection {
        case Left
        case Right
        case Up
        case Down
    }
}
