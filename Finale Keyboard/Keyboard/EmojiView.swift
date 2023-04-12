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
    
    var viewController: KeyboardViewController
    
    var emojiSections: [EmojiSection]
    
    var collectionViews = [UICollectionView]()
    
    var itemSize = 0.0
    
    let itemsInRow = 8
    let padding = 0.0
    
    var paginatedView: UIScrollView?
    var pageControl: PageControl?
    
    var originalPosition: CGFloat?
    var originalKeyboardPosition: CGFloat?
    var currentPositionTouched: CGPoint?
    
    var canDismiss = true
    var beganDismiss = false
    
    init (_ viewController: KeyboardViewController, frame: CGRect) {
        self.viewController = viewController
        self.emojiSections = ElegantEmojiPicker.getDefaultEmojiSections()
        super.init(frame: frame)
        
        LoadFavoriteEmoji()
        
        itemSize = (UIScreen.main.bounds.width-padding*2) / CGFloat(itemsInRow)
        let bottomButtonSize = frame.size.height-itemSize*3
        let bottomFunctionButtonWidth = bottomButtonSize * 1.2
        
        paginatedView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: itemSize*3))
        paginatedView!.backgroundColor = .clearInteractable
        paginatedView!.isPagingEnabled = true
        paginatedView!.delegate = self
        paginatedView!.contentSize = CGSize(width: frame.size.width*CGFloat(emojiSections.count), height: itemSize*3)
        paginatedView!.showsHorizontalScrollIndicator = false
        
        pageControl = PageControl(frame: CGRect(x: bottomFunctionButtonWidth, y: itemSize*3, width: frame.size.width-bottomFunctionButtonWidth*2, height: bottomButtonSize))
        pageControl?.emojiView = self
        pageControl?.Setup()
        
        for i in 0..<emojiSections.count {
            let collectionView = CollectionView(i: i)
            collectionViews.append(collectionView)
            paginatedView?.addSubview(collectionView)
        }
        
        let button = UIButton(frame: CGRect(x: frame.size.width-bottomFunctionButtonWidth, y: itemSize*3, width: bottomFunctionButtonWidth, height: bottomButtonSize))
        button.setImage(UIImage(systemName: "delete.left.fill"), for: .normal)
        button.imageView?.tintColor = .gray
        button.addTarget(self, action: #selector(Backspace), for: .touchUpInside)
        button.backgroundColor = .clearInteractable
        
        let button1 = UIButton(frame: CGRect(x: 0, y: itemSize*3, width: bottomFunctionButtonWidth, height: bottomButtonSize))
        button1.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button1.imageView?.tintColor = .gray
        button1.addTarget(self, action: #selector(ToggleSearchEmojiView), for: .touchUpInside)
        button1.backgroundColor = .clearInteractable
        
        self.addSubview(button)
        self.addSubview(button1)
        self.addSubview(paginatedView!)
        self.addSubview(pageControl!)
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
    
    func CollectionView (i: Int) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let view = UICollectionView(frame: CGRect(x: CGFloat(i) * frame.size.width, y: 0, width: frame.size.width, height: itemSize*3), collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(EmojiCell.self, forCellWithReuseIdentifier: "emojiCell")
                
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PanGesture))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        return view
    }
    
    @objc func Backspace () {
        viewController.BackspaceAction()
    }
    @objc func ToggleSearchEmojiView () {
        if KeyboardViewController.currentViewType == .SearchEmoji { return }
        viewController.BuildEmojiSearchView()
        viewController.ToggleEmojiView()
        KeyboardViewController.currentViewType = .SearchEmoji
        
        HapticFeedback.GestureImpactOccurred()
    }
    @objc func PanGesture (panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view as! UICollectionView
        if view.contentOffset.y > 0 || !canDismiss  {return}
        
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began {
            originalPosition = self.frame.origin.y
            originalKeyboardPosition = viewController.topRowView?.frame.origin.y
            currentPositionTouched = panGesture.location(in: self)
            beganDismiss = true
        } else if panGesture.state == .changed {
            if (!beganDismiss) {return}
            self.frame.origin.y = translation.y
            viewController.topRowView?.frame.origin.y = translation.y - viewController.buttonHeight*3
            viewController.middleRowView?.frame.origin.y = translation.y - viewController.buttonHeight*2
            viewController.bottomRowView?.frame.origin.y = translation.y - viewController.buttonHeight
        } else if panGesture.state == .ended {
            if (!beganDismiss) {return}
            let velocity = panGesture.velocity(in: self)

              if velocity.y >= 400 {
                UIView.animate(withDuration: 0.2) {
                    self.viewController.ToggleEmojiView()
                }
              } else {
                UIView.animate(withDuration: 0.2) {
                    self.frame.origin.y = self.originalPosition!
                    self.viewController.topRowView?.frame.origin.y = self.originalKeyboardPosition!
                    self.viewController.middleRowView?.frame.origin.y = self.originalKeyboardPosition! - self.viewController.buttonHeight
                    self.viewController.bottomRowView?.frame.origin.y = self.originalKeyboardPosition! - self.viewController.buttonHeight*2
                }
              }
            beganDismiss = false
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == paginatedView {
            pageControl!.SetCurrentPageColor(index: Int(round(scrollView.contentOffset.x/frame.width)))
            canDismiss = false
            if scrollView.contentOffset.x/frame.width < -0.15 {
                ToggleSearchEmojiView()
            }
        } else {
            scrollView.bounces = (scrollView.contentOffset.y > 10)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        canDismiss = true
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        canDismiss = true
    }
    
    func ResetView () {
        pageControl?.SetCurrentPageColor(index: 0)
        var f: CGRect = paginatedView!.frame
        f.origin.x = 0
        f.origin.y = 0
        paginatedView?.scrollRectToVisible(f, animated: false)
        
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
        
        cell.Setup(emoji: emoji, viewController: viewController)
        
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
    
    weak var viewController: KeyboardViewController?
    var emoji: Emoji?
    
    var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    func Setup (emoji: Emoji, viewController: KeyboardViewController) {
        self.viewController = viewController
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
        
        viewController?.TypeEmoji(emoji: emoji.emoji)
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

class PageControl: UIView {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    var buttons = [UIButton]()
    var emojiView: EmojiView?
    
    var currentPage: Int = 0
    
    override init (frame: CGRect) {
        super.init(frame: frame)
    }
    
    func SetCurrentPageColor (index: Int) {
        for i in 0..<buttons.count {
            if i == index {buttons[i].backgroundColor = .lightGray}
            else {buttons[i].backgroundColor = .clearInteractable}
        }
        currentPage = index
    }
    
    func Setup () {
        let numberOfIcons: CGFloat = CGFloat(emojiView!.emojiSections.count)
        let itemSize: CGFloat = frame.height
        let spacing: CGFloat = (frame.width - numberOfIcons * itemSize)/(numberOfIcons+1.0)
        
        
        for i in 0..<Int(numberOfIcons) {
            let button = UIButton(frame: CGRect(x: spacing * (1+CGFloat(i))+itemSize*CGFloat(i), y: 0, width: itemSize, height: itemSize))
            button.setImage(emojiView?.emojiSections[i].icon?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.imageView?.tintColor = .darkGray
            button.layer.cornerRadius = itemSize*0.5
            button.addTarget(self, action: #selector(ButtonPress), for: .touchUpInside)
            button.tag = i
            buttons.append(button)
            self.addSubview(button)
        }
        SetCurrentPageColor(index: 0)
    }
    
    @objc func ButtonPress (sender: UIButton) {
        SetCurrentPageColor(index: sender.tag)
        
        var f: CGRect = emojiView!.paginatedView!.frame
        f.origin.x = emojiView!.paginatedView!.frame.size.width * CGFloat(sender.tag)
        f.origin.y = 0
        emojiView?.paginatedView?.scrollRectToVisible(f, animated: false)
        emojiView?.canDismiss = true
    }
}
