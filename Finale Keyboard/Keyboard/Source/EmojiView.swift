//
//  EmojiViewController.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/4/22.
//

import UIKit
import SwiftUI
import ElegantEmojiPicker

class EmojiView: UIView, UIScrollViewDelegate {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var emojiSections: [EmojiSection]
    
    var collectionViews = [UICollectionView]()
    
    let toolbarHeight = 30.0
    
    var paginatedView = UIScrollView()
    var pageControl = PageControl()
    
    init () {
        self.emojiSections = ElegantEmojiPicker.getDefaultEmojiSections()
        super.init(frame: .zero)
        
        LoadFavoriteEmoji()
        
        let leadingButton = UIButton()
        leadingButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        leadingButton.imageView?.tintColor = .gray
        leadingButton.addTarget(self, action: #selector(ToggleSearchEmojiView), for: .touchUpInside)
        leadingButton.backgroundColor = .clearInteractable
        self.addSubview(leadingButton, anchors: [.safeAreaLeading(0), .height(toolbarHeight), .aspectRatio(widthToHeight: 1), .bottom(0)])
        
        let trailingButton = UIButton()
        trailingButton.setImage(UIImage(systemName: "delete.left.fill"), for: .normal)
        trailingButton.imageView?.tintColor = .gray
        trailingButton.addTarget(self, action: #selector(Backspace), for: .touchUpInside)
        trailingButton.backgroundColor = .clearInteractable
        self.addSubview(trailingButton, anchors: [.safeAreaTrailing(0), .height(toolbarHeight), .aspectRatio(widthToHeight: 1), .bottom(0)])
        
        pageControl.Setup(self)
        self.addSubview(pageControl, anchors: [.bottom(0), .leadingToTrailing(leadingButton, 0), .height(toolbarHeight), .trailingToLeading(trailingButton, 0)])
        
        paginatedView.backgroundColor = .clearInteractable
        paginatedView.isPagingEnabled = true
        paginatedView.delegate = self
        paginatedView.showsHorizontalScrollIndicator = false
        self.addSubview(paginatedView, anchors: [.bottomToTop(pageControl, 0), .top(0), .safeAreaLeading(0), .safeAreaTrailing(0)])
        let scrollContent = paginatedView.setupContentContainer(scrollDirection: .Horizontal)
        
        for _ in emojiSections {
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: EightItemsFlowLayout())
            collectionView.backgroundColor = .clear
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "emojiCell")
                    
            let pan = UIPanGestureRecognizer(target: self, action: #selector(PanGesture))
            pan.delegate = self
            collectionView.addGestureRecognizer(pan)
            
            let prevCollectionView: UIView? = scrollContent.subviews.last
            let leading: LayoutAnchor = prevCollectionView == nil ? .leading(0) : .leadingToTrailing(prevCollectionView!, 0)
            scrollContent.addSubview(collectionView, anchors: [.top(0), .bottom(0), leading])
            if prevCollectionView != nil { collectionView.widthAnchor.constraint(equalTo: prevCollectionView!.widthAnchor).isActive = true }
            else { collectionView.widthAnchor.constraint(equalTo: paginatedView.frameLayoutGuide.widthAnchor).isActive = true }
            
            collectionViews.append(collectionView)
        }
        if let last = scrollContent.subviews.last { last.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor).isActive = true }
    }
    
    func LoadFavoriteEmoji () {
        let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        if let favoritesArray = userDefaults?.value(forKey: "FINALE_DEV_APP_favorite_emoji") as? [String] {
            var areFavoritesEmpty = true
            for emoji in favoritesArray {
                if emoji != "" { areFavoritesEmpty = false }
            }
            if !areFavoritesEmpty {
                let favoritesSection = EmojiSection(title: "Favorites", icon: UIImage(systemName: "heart"), emojis: favoritesArray.map { emojiString in
                    Emoji(emoji: emojiString, description: "", category: .Activities, aliases: [], tags: [], supportsSkinTones: false, iOSVersion: "")
                })
                emojiSections.insert(favoritesSection, at: 0)
            }
        }
    }
    
    @objc func Backspace () {
        FinaleKeyboard.instance.BackspaceAction()
    }
    @objc func ToggleSearchEmojiView () {
        if FinaleKeyboard.currentViewType == .SearchEmoji { return }
        FinaleKeyboard.instance.BuildKeyboardView(viewType: .SearchEmoji)
        FinaleKeyboard.instance.ToggleEmojiView()
        FinaleKeyboard.currentViewType = .SearchEmoji
        
        HapticFeedback.GestureImpactOccurred()
    }
    
    var originalOffset = 0.0
    @objc func PanGesture (panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view as! UICollectionView
        if view.contentOffset.y > 0  {return}
        
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began {
            originalOffset = FinaleKeyboard.instance.topRowTopConstraint!.constant
        } else if panGesture.state == .changed {
            FinaleKeyboard.instance.topRowTopConstraint?.constant = originalOffset + translation.y
            FinaleKeyboard.instance.bottomRowBottomConstraint?.constant = originalOffset + translation.y
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: self)

            if velocity.y >= 400 {
                FinaleKeyboard.instance.ToggleEmojiView()
            } else {
                FinaleKeyboard.instance.topRowTopConstraint?.constant = originalOffset
                FinaleKeyboard.instance.bottomRowBottomConstraint?.constant = originalOffset
                UIView.animate(withDuration: 0.2) {
                    FinaleKeyboard.instance.view.layoutIfNeeded()
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == paginatedView {
            pageControl.SetHighlightPosition(scrollView.contentOffset.x / scrollView.frame.width)
            if scrollView.contentOffset.x/frame.width < -0.15 {
                ToggleSearchEmojiView()
            }
        } else {
            scrollView.bounces = (scrollView.contentOffset.y > 10)
        }
    }
    
    func ScrollToPage(_ page: Int) {
        paginatedView.scrollRectToVisible(CGRect(origin: CGPoint(x: paginatedView.frame.size.width * CGFloat(page), y: 0), size: paginatedView.frame.size), animated: true)
    }
    
    func ResetView () {
        paginatedView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 0), size: paginatedView.frame.size), animated: false)
        
        collectionViews.forEach {
            $0.scrollRectToVisible(CGRect(x: 0, y: 0, width: $0.frame.width, height: $0.frame.height), animated: false)
        }
    }
}

extension EmojiView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       return true
    }
}

extension EmojiView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collectionIndex = collectionViews.firstIndex(of: collectionView) else { return 0 }
        return emojiSections[collectionIndex].emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath) as! EmojiCell
        
        guard let collectionIndex = collectionViews.firstIndex(of: collectionView) else { return cell }
        let emoji = emojiSections[collectionIndex].emojis[indexPath.row]
        
        cell.Setup(emoji: emoji)
        
        return cell
    }
}
extension EmojiView: UICollectionViewDelegate {
 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let x = collectionView.cellForItem(at: indexPath) as! EmojiCell
        x.TypeEmoji()
    }
}

class EmojiCell: UICollectionViewCell {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var emoji: Emoji?
    
    var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    func Setup (emoji: Emoji) {
        self.emoji = emoji
        
        label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        label?.backgroundColor = .clear
        label?.text = emoji.emoji
        label?.font = label!.font.withSize(32)
        label?.textAlignment = .center
        
        addSubview(label!)
    }
    
    func TypeEmoji () {
        guard let emoji = emoji else { return }
        
        FinaleKeyboard.instance.TypeEmoji(emoji: emoji.emoji)
        UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            self.label?.frame.origin.y -= self.label!.frame.size.height*0.3
            self.label?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        } completion: { _ in
            UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                self.label?.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.label?.frame.origin.y = 0
            }
        }
    }
    
    override func prepareForReuse () {
        super.prepareForReuse()
        for view in subviews{
            view.removeFromSuperview()
        }
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
        SetHighlightPosition(emojiView!.paginatedView.contentOffset.x / emojiView!.paginatedView.frame.width)
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
