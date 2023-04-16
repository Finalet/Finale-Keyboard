//
//  PageControl.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/13/23.
//

import Foundation
import UIKit

class PageControl: UIView {
    var buttons = [UIButton]()
    
    var highlighter = UIView()
    var highlighterLeadingConstraint: NSLayoutConstraint?
    
    var emojiView: EmojiView?
    
    let height = 30.0
    
    func Setup (_ emojiView: EmojiView) {
        self.emojiView = emojiView
        
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        let leadingButton = UIButton()
        leadingButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        leadingButton.imageView?.tintColor = .systemGray
        leadingButton.addTarget(self, action: #selector(ToggleSearchEmojiView), for: .touchUpInside)
        leadingButton.backgroundColor = .clearInteractable
        self.addSubview(leadingButton, anchors: [.leading(0), .top(0), .aspectRatio(widthToHeight: 1), .bottom(0)])
        
        let trailingButton = UIButton()
        trailingButton.setImage(UIImage(systemName: "delete.left.fill"), for: .normal)
        trailingButton.imageView?.tintColor = .systemGray
        trailingButton.addTarget(self, action: #selector(Backspace), for: .touchUpInside)
        trailingButton.backgroundColor = .clearInteractable
        self.addSubview(trailingButton, anchors: [.trailing(0), .top(0), .aspectRatio(widthToHeight: 1), .bottom(0)])
        
        highlighter.backgroundColor = .systemGray3
        self.addSubview(highlighter, anchors: [.top(0), .bottom(0), .aspectRatio(widthToHeight: 1)])
        highlighterLeadingConstraint = highlighter.centerXAnchor.constraint(equalTo: self.leadingAnchor)
        highlighterLeadingConstraint?.isActive = true
        
        for section in emojiView.emojiSections {
            let button = UIButton()
            button.backgroundColor = .clearInteractable
            button.setImage(section.icon?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.tintColor = .systemGray
            button.addTarget(self, action: #selector(ButtonPress), for: .touchUpInside)
            button.tag = buttons.count
            self.addSubview(button, anchors: [.top(0), .bottom(0), .leadingToTrailing(buttons.last ?? leadingButton, 0)])
            if buttons.count > 0 { button.widthAnchor.constraint(equalTo: buttons[0].widthAnchor).isActive = true }
            
            buttons.append(button)
        }
        if let last = buttons.last { last.trailingAnchor.constraint(equalTo: trailingButton.leadingAnchor).isActive = true }
        
        SetHighlightPosition(0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        highlighter.layer.cornerRadius = highlighter.frame.height*0.5
        SetHighlightPosition(emojiView!.masterCollection.contentOffset.x / emojiView!.masterCollection.frame.width)
    }
    
    func SetHighlightPosition (_ pos: CGFloat, animated: Bool = false) {
        let floor = Int(floor(pos))
        let ceil = Int(ceil(pos))
        var lerp = pos.truncatingRemainder(dividingBy: 1)
        if lerp < 0 { lerp += 1 }
        let first: UIView? = buttons.indices.contains(floor) ? buttons[floor] : nil
        let second: UIView? = buttons.indices.contains(ceil) ? buttons[ceil] : nil
        
        highlighterLeadingConstraint?.constant = (first?.center.x ?? -buttons.first!.frame.width*0.5) * (1-lerp) + (second?.center.x ?? self.frame.width + buttons.first!.frame.width*0.5) * lerp
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        }
    }
    
    @objc func ButtonPress (sender: UIButton) {
        emojiView?.ScrollToPage(sender.tag)
    }
    
    @objc func Backspace () {
        FinaleKeyboard.instance.BackspaceAction()
    }
    @objc func ToggleSearchEmojiView () {
        FinaleKeyboard.instance.ToggleSearchEmojiView()
    }
}
