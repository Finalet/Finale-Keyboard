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
    
    func Setup (_ emojiView: EmojiView) {
        self.emojiView = emojiView
        
        highlighter.backgroundColor = .lightGray
        self.addSubview(highlighter, anchors: [.top(0), .bottom(0), .aspectRatio(widthToHeight: 1)])
        highlighterLeadingConstraint = highlighter.centerXAnchor.constraint(equalTo: self.leadingAnchor)
        highlighterLeadingConstraint?.isActive = true
        
        for section in emojiView.emojiSections {
            let button = UIButton()
            button.setImage(section.icon?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.tintColor = .darkGray
            button.addTarget(self, action: #selector(ButtonPress), for: .touchUpInside)
            button.tag = buttons.count
            let prevButton: UIView? = buttons.last
            let leading: LayoutAnchor = prevButton == nil ? .leading(0) : .leadingToTrailing(prevButton!, 0)
            self.addSubview(button, anchors: [.top(0), .bottom(0), leading])
            if prevButton != nil { button.widthAnchor.constraint(equalTo: prevButton!.widthAnchor).isActive = true }
            
            buttons.append(button)
        }
        if let last = buttons.last { last.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true }
        
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
}
