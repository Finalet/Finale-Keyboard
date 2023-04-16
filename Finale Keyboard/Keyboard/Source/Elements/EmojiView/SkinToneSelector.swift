//
//  SkintonePicker.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/14/23.
//

import Foundation
import UIKit
import ElegantEmojiPicker

class SkinToneSelector: UIView {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented")}
    
    let padding = 8.0
    
    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    
    let collectionView: EmojiCollectionCell
    let emojiCell: EmojiCell
    
    init (_ standardEmoji: Emoji, fontSize: CGFloat, collectionView: EmojiCollectionCell, emojiCell: EmojiCell) {
        self.collectionView = collectionView
        self.emojiCell = emojiCell
        super.init(frame: .zero)
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 8
        
        blur.clipsToBounds = true
        blur.alpha = 0
        self.addSubview(blur, anchors: LayoutAnchor.fullFrame)
        
        let yellow = SkinToneButton(standardEmoji: standardEmoji, skinTone: nil, fontSize: fontSize, emojiCell: emojiCell)
        self.addSubview(yellow, anchors: [.leading(padding), .top(padding), .bottom(padding)])
        
        for tone in EmojiSkinTone.allCases {
            let button = SkinToneButton(standardEmoji: standardEmoji, skinTone: tone, fontSize: fontSize, emojiCell: emojiCell)
            self.addSubview(button, anchors: [.leadingToTrailing(self.subviews.last!, padding), .top(padding), .bottom(padding)])
        }
        
        if let last = self.subviews.last { last.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -padding).isActive = true }
        
        DispatchQueue.main.async {
            self.Appear()
        }
    }
    
    func Appear () {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        UIView.animate(withDuration: 0.25) {
            self.blur.alpha = 1
        }
        for i in 1..<self.subviews.count {
            self.subviews[i].transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            Animate(i, duration: 0.5) {
                self.subviews[i].alpha = 1
                self.subviews[i].transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }
    }
    
    func Disappear () {
        UIView.animate(withDuration: 0.25) {
            self.blur.alpha = 0
        }
        for i in 1..<self.subviews.count {
            Animate(i, duration: 0.2) {
                self.subviews[i].alpha = 0
                self.subviews[i].transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.subviews.count-1)*0.05 + 0.2) {
            self.removeFromSuperview()
        }
    }
    
    func Animate (_ i: Int, duration: CGFloat, animation: @escaping ()->())  {
        UIView.animate(withDuration: duration, delay: Double(i-1)*0.05, usingSpringWithDamping: 0.5, initialSpringVelocity: 0) {
            animation()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blur.layer.cornerRadius = blur.frame.height * 0.5
    }
    
    class SkinToneButton: UILabel {
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented")}
        
        let skinTone: EmojiSkinTone?
        let standardEmoji: Emoji
        let skinTonedEmoji: Emoji
        
        let emojiCell: EmojiCell
        
        init (standardEmoji: Emoji, skinTone: EmojiSkinTone?, fontSize: CGFloat, emojiCell: EmojiCell) {
            self.skinTone = skinTone
            self.standardEmoji = standardEmoji
            self.skinTonedEmoji = standardEmoji.duplicate(skinTone)
            self.emojiCell = emojiCell
            super.init(frame: .zero)
            
            self.text = skinTonedEmoji.emoji
            self.font = .systemFont(ofSize: fontSize)
            self.isUserInteractionEnabled = true
            self.setContentCompressionResistancePriority(.required, for: .horizontal)
            self.alpha = 0
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TapTone)))
        }
        
        @objc func TapTone (_ sender: UITapGestureRecognizer) {
            FinaleKeyboard.instance.TypeEmoji(emoji: skinTonedEmoji.emoji)
            ElegantEmojiPicker.PersistSkinTone(originalEmoji: standardEmoji, skinTone: skinTone)
            
            emojiCell.Setup(emoji: skinTonedEmoji)
            
            HapticFeedback.TypingImpactOccurred()
            let originY = self.frame.origin.y
            UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                self.frame.origin.y -= self.frame.size.height*0.5
                self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            } completion: { _ in
                UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.frame.origin.y = originY
                }
            }
        }
    }
}
