//
//  EmojiCollectionView.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/13/23.
//

import Foundation
import UIKit
import ElegantEmojiPicker

class EmojiCollectionCell: UICollectionViewCell, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let collectionView: UICollectionView
    var emojiSection: EmojiSection?
    
    var skinToneSelector: SkinToneSelector?
    var currentSkinToneEmojiIndexPath: IndexPath?
    
    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: EightItemsFlowLayout())
        super.init(frame: frame)
        
        backgroundColor = .clearInteractable
        
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "emojiCell")
        self.addSubview(collectionView, anchors: LayoutAnchor.fullFrame)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PanGesture))
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)
    }
    
    func Setup(_ emojiSection: EmojiSection) {
        self.emojiSection = emojiSection
        collectionView.reloadData()
    }
    
    var startPosY = 0.0
    @objc func PanGesture (panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view as! UICollectionView
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began {
            startPosY = view.contentOffset.y
        }
        
        if view.contentOffset.y > 0 || translation.y < 0 || !FinaleKeyboard.instance.emojiView.canDismiss {
            ResetPan()
            return
        }
        
        if panGesture.state == .changed {
            FinaleKeyboard.instance.keysViewTopConstraint?.constant = -FinaleKeyboard.instance.view.frame.height + translation.y - startPosY
            FinaleKeyboard.instance.keysViewBottomConstraint?.constant = -FinaleKeyboard.instance.view.frame.height + translation.y - startPosY
            HideEmojiPicker()
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: self)

            if velocity.y >= 400 {
                FinaleKeyboard.instance.CloseEmoji()
            } else {
                ResetPan()
            }
        }
    }
    
    func ResetPan () {
        let offset = -FinaleKeyboard.instance.view.frame.height
        if FinaleKeyboard.currentViewType != .Emoji { return }
        if FinaleKeyboard.instance.keysViewTopConstraint?.constant == offset && FinaleKeyboard.instance.keysViewBottomConstraint?.constant == offset { return }
        
        FinaleKeyboard.instance.keysViewTopConstraint?.constant = -FinaleKeyboard.instance.view.frame.height
        FinaleKeyboard.instance.keysViewBottomConstraint?.constant = -FinaleKeyboard.instance.view.frame.height
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
            FinaleKeyboard.instance.view.layoutIfNeeded()
        }
    }
    
    func ShowEmojiPicker (emoji: Emoji, cell: EmojiCell) {
        skinToneSelector?.removeFromSuperview()
        skinToneSelector = SkinToneSelector(emoji.duplicate(nil), fontSize: cell.label.font.pointSize*0.6, collectionView: self, emojiCell: cell)
        skinToneSelector?.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(skinToneSelector!)
        skinToneSelector?.topAnchor.constraint(greaterThanOrEqualTo: FinaleKeyboard.instance.view.topAnchor, constant: 8).isActive = true
        skinToneSelector?.leadingAnchor.constraint(greaterThanOrEqualTo: FinaleKeyboard.instance.view.leadingAnchor, constant: 8).isActive = true
        skinToneSelector?.trailingAnchor.constraint(lessThanOrEqualTo: FinaleKeyboard.instance.view.trailingAnchor, constant: -8).isActive = true
        skinToneSelector?.leadingAnchor.constraint(lessThanOrEqualTo: cell.leadingAnchor).isActive = true
        skinToneSelector?.bottomAnchor.constraint(greaterThanOrEqualTo: cell.topAnchor).isActive = true
        
        currentSkinToneEmojiIndexPath = collectionView.indexPath(for: cell)
    }
    
    func HideEmojiPicker () {
        skinToneSelector?.Disappear()
        skinToneSelector = nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounces = (scrollView.contentOffset.y > 10)
        HideEmojiPicker ()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiSection?.emojis.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath) as! EmojiCell
        
        if let emoji = emojiSection?.emojis[indexPath.row] {
            cell.Setup(emoji: emoji, collectionView: self)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if skinToneSelector != nil {
            if currentSkinToneEmojiIndexPath != indexPath {
                HideEmojiPicker()
            }
            return
        }
        
        (collectionView.cellForItem(at: indexPath) as? EmojiCell)?.TypeEmoji()
    }
}

class EmojiCell: UICollectionViewCell {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var emoji: Emoji?
    var collectionView: EmojiCollectionCell?
    
    var label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        label.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        label.font = label.font.withSize(32)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        addSubview(label)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(LongPress))
        longPress.minimumPressDuration = 0.3
        longPress.cancelsTouchesInView = false
        self.addGestureRecognizer(longPress)
    }
    
    func Setup (emoji: Emoji, collectionView: EmojiCollectionCell) {
        self.emoji = emoji
        self.collectionView = collectionView
        
        label.text = emoji.emoji
    }
    
    func Setup(emoji: Emoji) {
        self.emoji = emoji
        label.text = emoji.emoji
    }
    
    func TypeEmoji () {
        guard let emoji = emoji else { return }
        
        FinaleKeyboard.instance.TypeEmoji(emoji: emoji.emoji)
        HapticFeedback.TypingImpactOccurred()
        UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            self.label.frame.origin.y -= self.label.frame.size.height*0.3
            self.label.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        } completion: { _ in
            UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                self.label.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.label.frame.origin.y = 0
            }
        }
    }
    
    @objc func LongPress (_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if let emoji = emoji, emoji.supportsSkinTones {
                collectionView?.ShowEmojiPicker(emoji: emoji, cell: self)
            }
        }
    }
}

class MasterFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        configureLayout()
    }

    private func configureLayout() {
        guard let collectionView = collectionView else { return }
        
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        scrollDirection = .horizontal
        
        itemSize = collectionView.frame.size
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return collectionView?.bounds.size != newBounds.size
    }
}

class EightItemsFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        configureLayout()
    }

    private func configureLayout() {
        guard let collectionView = collectionView else { return }

        let itemsInRow: CGFloat = collectionView.bounds.width < 600 ? 8 : 16

        minimumInteritemSpacing = 0
        minimumLineSpacing = 0

        let itemWidth = collectionView.bounds.width / itemsInRow

        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return collectionView?.bounds.size != newBounds.size
    }
}
