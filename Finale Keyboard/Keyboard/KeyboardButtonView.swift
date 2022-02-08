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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clearInteractable
        
        titleLabel!.font = UIFont(name: "Gilroy-Medium", size: 20)
        
        calloutWidth = frame.height * 0.75
        calloutHeight = calloutWidth * 1.1
        
        calloutView = UIView(frame: CGRect(x: (frame.width - calloutWidth)*0.5, y: (frame.height - calloutHeight)*0.5, width: calloutWidth, height: calloutHeight))
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
        
        let touch = UITapGestureRecognizer(target: self, action: #selector(Touch))
        self.addGestureRecognizer(touch)
    }
    
    @objc func Touch () {
        viewController?.UseAction(action: action)
    }
    
    func SetupButton () {
        setTitle(action.actionTitle, for: .normal)
        setTitleColor(.systemPrimary, for: .normal)
        calloutLabel.text = titleLabel!.text
        calloutLabel.textColor = titleLabel?.textColor.withAlphaComponent(0)
        
        if (action.actionType == .Function) {
            setImage(getFunctionActionIcon(function: action.functionType), for: .normal)
            imageView?.tintColor = .lightGray
            self.bringSubviewToFront(imageView!)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        ShowCallout()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        HideCallout()
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
        UIView.animate(withDuration: 0.26) {
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
        
        UIView.animate(withDuration: 0.26, delay: 0, options: .curveEaseOut) {
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
            self.calloutView.frame.origin.x = 0
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
            imageView?.tintColor = KeyboardViewController.ShouldCapitalize() ? .systemPrimary : .lightGray
            if KeyboardViewController.currentViewType == .Characters { setImage(getFunctionActionIcon(function: KeyboardViewController.isCaps ? .Caps : .Shift), for: .normal) }
            else if KeyboardViewController.currentViewType == .Symbols { setImage(getFunctionActionIcon(function: .SymbolsShift), for: .normal) }
            else if KeyboardViewController.currentViewType == .ExtraSymbols { setImage(getFunctionActionIcon(function: .SymbolsShift), for: .normal) }
        } else {
            imageView?.tintColor = .lightGray
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
            return UIImage(systemName: "number", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))!
        case .ExtraSymbolsShift:
            return UIImage(systemName: "123.rectangle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))!
        case .Caps:
            return UIImage(systemName: "arrow.up.to.line", withConfiguration: UIImage.SymbolConfiguration(weight: .black))!
        case .Backspace:
            return UIImage(systemName: "delete.left.fill")!
        case .none:
            return UIImage(systemName: "exclamationmark.triangle")!
        }
    }
}
