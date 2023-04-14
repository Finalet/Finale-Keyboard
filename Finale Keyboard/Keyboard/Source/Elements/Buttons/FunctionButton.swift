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
    
    let function: Function
    
    init(_ function: Function) {
        self.function = function
        super.init()
        
        calloutView.backgroundColor = UIColor.gray.withAlphaComponent(0.6)
        calloutView.layer.cornerRadius = 5
        calloutView.alpha = 0
        self.addSubview(calloutView, anchors: [.heightMultiplier(0.8), .centerX(0), .centerY(0), .widthMultiplier(1)])
        
        iconView.image = function.icon
        iconView.tintColor = .systemGray
        iconView.contentMode = .scaleAspectFit
        self.addSubview(iconView, anchors: [.widthMultiplier(1), .widthMultiplier(0.6), .centerY(0), .centerX(0)])
    }
    
    override func OnTapBegin(_ sender: UILongPressGestureRecognizer) {
        if function == .Backspace { FinaleKeyboard.instance.LongPressDelete(backspace: true) }
        else if function == .Shift { FinaleKeyboard.instance.LongPressShift(button: self) }
    }
    
    override func OnTapEnded(_ sender: UILongPressGestureRecognizer) {
        function.TapAction()
    }
    
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
        if function == .Shift {
            iconView.tintColor = FinaleKeyboard.instance.shouldCapitalize ? .label : .gray
            if FinaleKeyboard.currentViewType == .Characters { iconView.image = FinaleKeyboard.isCaps ? Function.Caps.icon : Function.Shift.icon }
            else if FinaleKeyboard.currentViewType == .Symbols { iconView.image = Function.SymbolsShift.icon }
            else if FinaleKeyboard.currentViewType == .ExtraSymbols { iconView.image = Function.ExtraSymbolsShift.icon }
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3) { [self] in
            calloutView.alpha = 0
            iconView.tintColor = function == .Shift ? (FinaleKeyboard.instance.shouldCapitalize ? .label : .gray) : .gray
        }
    }
}
