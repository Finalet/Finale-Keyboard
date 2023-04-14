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
       
    var emojiSections: [EmojiSection]
    
    let containerView = UIView()
    var masterCollection: UICollectionView!
    var pageControl = PageControl()
    
    var canDismiss = true
    
    init () {
        self.emojiSections = ElegantEmojiPicker.getDefaultEmojiSections()
        super.init(frame: .zero)
        
        LoadFavoriteEmoji()
        
        pageControl.Setup(self)
        self.addSubview(pageControl, anchors: [.bottom(0), .safeAreaLeading(0), .safeAreaTrailing(0)])
        
        self.addSubview(containerView, anchors: [.bottomToTop(pageControl, 0), .top(0), .safeAreaLeading(0), .safeAreaTrailing(0)])
        
        masterCollection = UICollectionView(frame: .zero, collectionViewLayout: MasterFlowLayout())
        masterCollection.isPagingEnabled = true
        masterCollection.backgroundColor = .clear
        masterCollection.dataSource = self
        masterCollection.delegate = self
        masterCollection.showsHorizontalScrollIndicator = false
        masterCollection.register(EmojiCollectionCell.self, forCellWithReuseIdentifier: "EmojiCollectionCell")
        containerView.addSubview(masterCollection, anchors: LayoutAnchor.fullFrame)
        
        let fadeGradient = CAGradientLayer()
        fadeGradient.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        fadeGradient.startPoint = CGPoint(x: 0, y: 0.9)
        fadeGradient.endPoint = CGPoint(x: 0, y: 1)
        containerView.layer.mask = fadeGradient
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.mask?.frame = containerView.bounds
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        canDismiss = false
        pageControl.SetHighlightPosition(scrollView.contentOffset.x / scrollView.frame.width)
        if scrollView.contentOffset.x/frame.width < -0.15 {
            FinaleKeyboard.instance.ToggleSearchEmojiView()
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
