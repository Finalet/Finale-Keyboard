//
//  EmojiViewController.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/4/22.
//

import UIKit
import SwiftUI
import ElegantEmojiPicker

class EmojiView: UIView, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let toolbarHeight = 30.0
    
    var emojiSections: [EmojiSection]
    
    var masterCollection: UICollectionView!
    var pageControl = PageControl()
    
    var canDismiss = true
    
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
        
        masterCollection = UICollectionView(frame: .zero, collectionViewLayout: MasterFlowLayout())
        masterCollection.isPagingEnabled = true
        masterCollection.backgroundColor = .clear
        masterCollection.dataSource = self
        masterCollection.delegate = self
        masterCollection.showsHorizontalScrollIndicator = false
        masterCollection.register(EmojiCollectionCell.self, forCellWithReuseIdentifier: "EmojiCollectionCell")
        self.addSubview(masterCollection, anchors: [.bottomToTop(pageControl, 0), .top(0), .safeAreaLeading(0), .safeAreaTrailing(0)])
        
        canDismiss = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCollectionCell", for: indexPath) as! EmojiCollectionCell
        
        cell.Setup(emojiSections[indexPath.row])
        
        return cell
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        canDismiss = false
        pageControl.SetHighlightPosition(scrollView.contentOffset.x / scrollView.frame.width)
        if scrollView.contentOffset.x/frame.width < -0.15 {
            ToggleSearchEmojiView()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        canDismiss = true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        canDismiss = true
    }
    
    func ScrollToPage(_ page: Int) {
        masterCollection.scrollToItem(at: IndexPath(row: page, section: 0), at: .centeredHorizontally, animated: true)
        canDismiss = true
    }
    
    func ResetView () {
        masterCollection.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        masterCollection.visibleCells.forEach {
            ($0 as? EmojiCollectionCell)?.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
        canDismiss = true
    }
}
