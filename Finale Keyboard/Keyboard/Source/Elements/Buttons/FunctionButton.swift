//
//  FunctionButton.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/14/23.
//

import Foundation
import UIKit

class FunctionButton: KeyboardButton {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let calloutView = UIView()
    let iconView = UIImageView()
    
    var function: Function
    
    init(_ function: Function) {
        self.function = function
        super.init()
        
        calloutView.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        calloutView.layer.cornerRadius = 5
        calloutView.alpha = 0
        self.addSubview(calloutView, anchors: [.heightMultiplier(0.8), .centerX(0), .centerY(0), .widthMultiplier(1)])
        
        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit
        self.addSubview(iconView, anchors: [.widthMultiplier(1), .widthMultiplier(0.6), .centerY(0), .centerX(0)])
        
        ChangeFunction(new: function)
    }
    
    func ChangeFunction(new: Function) {
        self.function = new
        iconView.image = function.icon
    }
    
    override func OnTapBegin(_ sender: UILongPressGestureRecognizer) {}
    
    override func OnTapChanged(_ sender: UILongPressGestureRecognizer) {}
    
    override func OnTapEnded(_ sender: UILongPressGestureRecognizer) {
        if didLongPress {
            function.LongPressEndedAction()
            return
        }
        
        function.TapAction()
        FinaleKeyboard.instance.MiddleRowReactAnimation()
    }
    
    override func OnLongPress(_ sender: UILongPressGestureRecognizer) {
        function.LongPressAction()
        HideCallout()
    }
    
    override func OnLongPressRepeating(_ sender: UILongPressGestureRecognizer) {}
    
    override func OnSwipe(direction: KeyboardButton.SwipeDirection) {
        if direction == .Right { function.SwipeRight() }
        else if direction == .Left { function.SwipeLeft() }
        else if direction == .Up { function.SwipeUp() }
        else if direction == .Down { function.SwipeDown() }
    }
    
    override func ShowCallout() {
        calloutView.alpha = 1
        iconView.tintColor = .label
    }
    
    override func HideCallout(direction: KeyboardButton.SwipeDirection? = nil) {
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: .allowUserInteraction) { [self] in
            calloutView.alpha = 0
            iconView.tintColor = .gray
        }
    }
    
    func ToggleHighlight (_ isOn: Bool) {
        iconView.tintColor = isOn ? .label : .gray
    }
}
