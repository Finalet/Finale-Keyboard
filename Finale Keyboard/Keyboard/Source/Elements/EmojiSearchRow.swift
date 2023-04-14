//
//  EmojiSearchRow.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/13/23.
//

import Foundation
import UIKit
import ElegantEmojiPicker

class EmojiSearchRow: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    let padding = 8.0
    
    var searchLabel = UILabel()
    var caret = UIView()
    var caretXConstraint: NSLayoutConstraint?
    
    var resultsPlaceholder = UILabel()
    var containerView = UIView()
    var collectionView: UICollectionView!
    
    var searchResults = [Emoji]()
    
    var scrollContent: UIView!
    
    let searchPlaceholderText = "Search emoji"
    let searchNoEmojiText = "No emoji found"
    
    init () {
        super.init(frame: .zero)
        
        searchLabel.text = " "
        searchLabel.layer.masksToBounds = true
        searchLabel.layer.cornerRadius = 6
        searchLabel.backgroundColor = .systemGray4
        self.addSubview(searchLabel, anchors: [.top(padding), .leading(padding), .bottom(0), .widthMultiplier(0.25)])
        
        resultsPlaceholder.text = searchPlaceholderText
        resultsPlaceholder.textColor = .systemGray
        self.addSubview(resultsPlaceholder, anchors: [.trailing(padding), .centerYtoCenterY(searchLabel, 0), .leadingToTrailing(searchLabel, padding)])
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = padding
        layout.minimumInteritemSpacing = padding
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: FinaleKeyboard.instance.emojiRowHeight-padding, height: FinaleKeyboard.instance.emojiRowHeight-padding)
        
        self.addSubview(containerView, anchors: [.trailing(0), .top(0), .bottom(-padding), .leadingToTrailing(searchLabel, 0)])
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "emojiCell")
        containerView.addSubview(collectionView, anchors: LayoutAnchor.fullFrame)
        
        let fadeGradient = CAGradientLayer()
        fadeGradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        fadeGradient.startPoint = CGPoint(x: 0, y: 0)
        fadeGradient.endPoint = CGPoint(x: 0.05, y: 0)
        containerView.layer.mask = fadeGradient
        
        caret.backgroundColor = .systemGray
        caret.layer.cornerRadius = 1
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseIn]) {
            self.caret.alpha = 0
        }
        searchLabel.addSubview(caret, anchors: [.top(padding*0.5), .bottom(padding*0.5), .width(2)])
        caretXConstraint = caret.leadingAnchor.constraint(equalTo: searchLabel.leadingAnchor, constant: searchLabel.intrinsicContentSize.width)
        caretXConstraint?.isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.mask?.frame = containerView.bounds
    }
    
    func TypeChar(_ character: String) {
        searchLabel.text?.append(character)
        UpdateEmojiSearch()
    }
    
    func BackspaceAction () {
        if searchLabel.text!.count <= 1 { return }
        searchLabel.text?.removeLast()
        UpdateEmojiSearch()
        FinaleKeyboard.instance.MiddleRowReactAnimation()
    }
    
    func SwipeRight () {
        searchLabel.text?.append(" ")
        UpdateEmojiSearch()
    }
    
    func Delete () {
        searchLabel.text? = " "
        UpdateEmojiSearch()
        FinaleKeyboard.instance.MiddleRowReactAnimation()
    }
    
    func UpdateEmojiSearch () {
        caretXConstraint?.constant = searchLabel.intrinsicContentSize.width > searchLabel.frame.width ? searchLabel.frame.width : searchLabel.intrinsicContentSize.width
        
        var searchTerm = searchLabel.text
        searchTerm?.removeFirst()
        guard let searchTerm = searchTerm else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.searchResults = ElegantEmojiPicker.getSearchResults(searchTerm, fromAvailable: FinaleKeyboard.instance.emojiView.emojiSections).suffix(20)

            DispatchQueue.main.async {
                if self.searchLabel.text!.isEmpty || self.searchLabel.text! == " " { self.resultsPlaceholder.text = self.searchPlaceholderText }
                else { self.resultsPlaceholder.text = self.searchResults.count == 0 ? self.searchNoEmojiText  : "" }

                self.collectionView.reloadData()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emojiCell", for: indexPath) as! EmojiCell
        
        cell.Setup(emoji: searchResults[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? EmojiCell)?.TypeEmoji()
    }
    
}
