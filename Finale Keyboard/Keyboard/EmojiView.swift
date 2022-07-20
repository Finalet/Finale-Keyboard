//
//  EmojiViewController.swift
//  Keyboard
//
//  Created by Grant Oganan on 2/4/22.
//

import UIKit
import SwiftUI

struct Emoji: Decodable {
    let emoji: String
    let description: String
    let category: EmojiCategory
}
struct Emoji14: Decodable {
    let name: String
    let group: String
}

enum EmojiCategory: String, Decodable {
    case SmileysEmotion = "Smileys & Emotion"
    case PeopleBody = "People & Body"
    case AnimalsNature = "Animals & Nature"
    case FoodDrink = "Food & Drink"
    case TravelPlaces = "Travel & Places"
    case Activities = "Activities"
    case Objects = "Objects"
    case Symbols = "Symbols"
    case Flags = "Flags"
}

class EmojiView: UIView, UIScrollViewDelegate {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var viewController: KeyboardViewController?
    
    var Favorites = [String](repeating: "", count: 32)
    var AllEmoji = [Emoji]()
    var SmileysEmotion = [Emoji]()
    var PeopleBody = [Emoji]()
    var AnimalsNature = [Emoji]()
    var FoodDrink = [Emoji]()
    var TravelPlaces =  [Emoji]()
    var Activities = [Emoji]()
    var Objects = [Emoji]()
    var Symbols = [Emoji]()
    var Flags = [Emoji]()
    
    var FavoritesView: UICollectionView?
    var SmileysEmotionView: UICollectionView?
    var PeopleBodyView: UICollectionView?
    var AnimalsNatureView: UICollectionView?
    var FoodDrinkView: UICollectionView?
    var TravelPlacesView: UICollectionView?
    var ActivitiesView: UICollectionView?
    var ObjectsView: UICollectionView?
    var SymbolsView: UICollectionView?
    var FlagsView: UICollectionView?
    
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
        
    override init (frame: CGRect) {
        super.init(frame: frame)
        InitArrays()
        
        itemSize = (UIScreen.main.bounds.width-padding*2) / CGFloat(itemsInRow)
        let bottomButtonSize = frame.size.height-itemSize*3
        let bottomFunctionButtonWidth = bottomButtonSize * 1.2
        
        paginatedView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: itemSize*3))
        paginatedView!.backgroundColor = .clearInteractable
        paginatedView!.isPagingEnabled = true
        paginatedView!.delegate = self
        paginatedView!.contentSize = CGSize(width: frame.size.width*CGFloat(areFavoriteEmpty() ? 9 : 10), height: itemSize*3)
        paginatedView!.showsHorizontalScrollIndicator = false
        
        pageControl = PageControl(frame: CGRect(x: bottomFunctionButtonWidth, y: itemSize*3, width: frame.size.width-bottomFunctionButtonWidth*2, height: bottomButtonSize))
        pageControl?.emojiView = self
        pageControl?.Setup()
        
        SetupCategoriesView()
        
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
    
    func SetupCategoriesView () {
        let x = areFavoriteEmpty()
        
        if (!x) { FavoritesView = CollectionView(i: 0) }
        SmileysEmotionView = CollectionView(i: x ? 0 : 1)
        PeopleBodyView = CollectionView(i: x ? 1 : 2)
        AnimalsNatureView = CollectionView(i: x ? 2 : 3)
        FoodDrinkView = CollectionView(i: x ? 3 : 4)
        TravelPlacesView = CollectionView(i: x ? 4 : 5)
        ActivitiesView = CollectionView(i: x ? 5 : 6)
        ObjectsView = CollectionView(i: x ? 6 : 7)
        SymbolsView = CollectionView(i: x ? 7 : 8)
        FlagsView = CollectionView(i: x ? 8 : 9)
        
        if (!x) { paginatedView!.addSubview(FavoritesView!) }
        
        paginatedView!.addSubview(SmileysEmotionView!)
        paginatedView!.addSubview(PeopleBodyView!)
        paginatedView!.addSubview(AnimalsNatureView!)
        paginatedView!.addSubview(FoodDrinkView!)
        paginatedView!.addSubview(TravelPlacesView!)
        paginatedView!.addSubview(ActivitiesView!)
        paginatedView!.addSubview(ObjectsView!)
        paginatedView!.addSubview(SymbolsView!)
        paginatedView!.addSubview(FlagsView!)
    }
    
    func CollectionView (i: Int) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let view = UICollectionView(frame: CGRect(x: CGFloat(i) * frame.size.width, y: 0, width: frame.size.width, height: itemSize*3), collectionViewLayout: layout)
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.cellID)
                
        let pan = UIPanGestureRecognizer(target: self, action: #selector(PanGesture))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        return view
    }
    
    func InitArrays () {
        let emojiData = (try? Data(contentsOf: Bundle.main.url(forResource: "Emoji Unicode 14.0", withExtension: "json")!))!
        let emojiDict = try! JSONDecoder().decode([String : Emoji14].self, from: emojiData)

        let orderedEmojiData = (try? Data(contentsOf: Bundle.main.url(forResource: "Ordered Emoji Unicode 14.0", withExtension: "json")!))!
        let orderedEmojies = try! JSONDecoder().decode([String].self, from: orderedEmojiData)
        
        for emoji in orderedEmojies {
            let newEmoji = Emoji(emoji: emoji, description: emojiDict[emoji]!.name, category: EmojiCategory(rawValue: emojiDict[emoji]!.group)!)
            AllEmoji.append(newEmoji)
            switch newEmoji.category {
            case .SmileysEmotion: SmileysEmotion.append(newEmoji)
            case .PeopleBody: PeopleBody.append(newEmoji)
            case .AnimalsNature: AnimalsNature.append(newEmoji)
            case .FoodDrink: FoodDrink.append(newEmoji)
            case .TravelPlaces: TravelPlaces.append(newEmoji)
            case .Activities: Activities.append(newEmoji)
            case .Objects: Objects.append(newEmoji)
            case .Symbols: Symbols.append(newEmoji)
            case .Flags: Flags.append(newEmoji)
            }
        }
        
        let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        let array = userDefaults?.value(forKey: "FINALE_DEV_APP_favorite_emoji")
        Favorites = array == nil ? Favorites : userDefaults?.value(forKey: "FINALE_DEV_APP_favorite_emoji") as! [String]
    }
    
    func getEmojiSearchResults (searchTerm: String) -> String {
        if searchTerm.isEmpty || searchTerm == " " { return ""}
        
        let result: [Emoji]
        if searchTerm.last == " " {
            var removeSpace = searchTerm
            removeSpace.removeLast()
            result = AllEmoji.filter { $0.description.range(of: "\\b\(removeSpace)\\b", options: [.regularExpression, .caseInsensitive]) != nil }
        } else {
            result = AllEmoji.filter { $0.description.contains(searchTerm) }
        }
        
        let sortedResult = result.sorted { $0.description.count < $1.description.count }
        
        var output = ""
        for i in 0..<6 {
            if sortedResult.count>i { output.append(sortedResult[i].emoji)
            } else { break }
        }
        return output
    }
    
    @objc func Backspace () {
        viewController?.BackspaceAction()
    }
    @objc func ToggleSearchEmojiView () {
        if KeyboardViewController.currentViewType == .SearchEmoji { return }
        viewController?.BuildEmojiSearchView()
        viewController?.ToggleEmojiView()
        KeyboardViewController.currentViewType = .SearchEmoji
        
        HapticFeedback.GestureImpactOccured()
    }
    @objc func PanGesture (panGesture: UIPanGestureRecognizer) {
        let view = panGesture.view as! UICollectionView
        if view.contentOffset.y > 0 || !canDismiss  {return}
        
        let translation = panGesture.translation(in: self)
        
        if panGesture.state == .began {
            originalPosition = self.frame.origin.y
            originalKeyboardPosition = viewController?.topRowView?.frame.origin.y
            currentPositionTouched = panGesture.location(in: self)
            beganDismiss = true
        } else if panGesture.state == .changed {
            if (!beganDismiss) {return}
            self.frame.origin.y = translation.y
            viewController?.topRowView?.frame.origin.y = translation.y - viewController!.buttonHeight*3
            viewController?.middleRowView?.frame.origin.y = translation.y - viewController!.buttonHeight*2
            viewController?.bottomRowView?.frame.origin.y = translation.y - viewController!.buttonHeight
        } else if panGesture.state == .ended {
            if (!beganDismiss) {return}
            let velocity = panGesture.velocity(in: self)

              if velocity.y >= 400 {
                UIView.animate(withDuration: 0.2) {
                    self.viewController?.ToggleEmojiView()
                }
              } else {
                UIView.animate(withDuration: 0.2) {
                    self.frame.origin.y = self.originalPosition!
                    self.viewController?.topRowView?.frame.origin.y = self.originalKeyboardPosition!
                    self.viewController?.middleRowView?.frame.origin.y = self.originalKeyboardPosition! - self.viewController!.buttonHeight
                    self.viewController?.bottomRowView?.frame.origin.y = self.originalKeyboardPosition! - self.viewController!.buttonHeight*2
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
        
        FavoritesView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: FavoritesView!.frame.width, height: FavoritesView!.frame.height), animated: false)
        SmileysEmotionView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: SmileysEmotionView!.frame.width, height: SmileysEmotionView!.frame.height), animated: false)
        PeopleBodyView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: PeopleBodyView!.frame.width, height: PeopleBodyView!.frame.height), animated: false)
        AnimalsNatureView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: AnimalsNatureView!.frame.width, height: AnimalsNatureView!.frame.height), animated: false)
        FoodDrinkView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: FoodDrinkView!.frame.width, height: FoodDrinkView!.frame.height), animated: false)
        TravelPlacesView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: TravelPlacesView!.frame.width, height: TravelPlacesView!.frame.height), animated: false)
        ActivitiesView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: ActivitiesView!.frame.width, height: ActivitiesView!.frame.height), animated: false)
        ObjectsView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: ObjectsView!.frame.width, height: ObjectsView!.frame.height), animated: false)
        SymbolsView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: SymbolsView!.frame.width, height: SymbolsView!.frame.height), animated: false)
        FlagsView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: FlagsView!.frame.width, height: FlagsView!.frame.height), animated: false)
    }
    
    func areFavoriteEmpty() -> Bool {
        for i in Favorites {
            if i != "" {
                return false
            }
        }
        return true
    }
}

extension EmojiView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       return true
    }
}

extension EmojiView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == FavoritesView {
            return Favorites.count
        } else if collectionView == SmileysEmotionView {
            return SmileysEmotion.count
        } else if collectionView == PeopleBodyView {
            return PeopleBody.count
        } else if collectionView == AnimalsNatureView {
            return AnimalsNature.count
        } else if collectionView == FoodDrinkView {
            return FoodDrink.count
        } else if collectionView == TravelPlacesView {
            return TravelPlaces.count
        } else if collectionView == ActivitiesView {
            return Activities.count
        } else if collectionView == ObjectsView {
            return Objects.count
        } else if collectionView == SymbolsView {
            return Symbols.count
        } else if collectionView == FlagsView {
            return Flags.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EmojiCell
        
        if collectionView == FavoritesView {
            cell.Setup(emoji: Favorites[indexPath.row], viewController: viewController!)
            return cell
        }
        
        var array = [Emoji]()
        if collectionView == SmileysEmotionView {
            array = SmileysEmotion
        } else if collectionView == PeopleBodyView {
            array = PeopleBody
        } else if collectionView == AnimalsNatureView {
            array = AnimalsNature
        } else if collectionView == FoodDrinkView {
            array = FoodDrink
        } else if collectionView == TravelPlacesView {
            array = TravelPlaces
        } else if collectionView == ActivitiesView {
            array = Activities
        } else if collectionView == ObjectsView {
            array = Objects
        } else if collectionView == SymbolsView {
            array = Symbols
        } else if collectionView == FlagsView {
            array = Flags
        }
        
        cell.Setup(emoji: array[indexPath.row].emoji, viewController: viewController!)
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
    
    static let cellID = "cell"
    weak var viewController: KeyboardViewController?
    var emoji = ""
    
    var label: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func Setup (emoji: String, viewController: KeyboardViewController) {
        label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        self.viewController = viewController
        self.emoji = emoji
        label!.backgroundColor = .clear
        label!.text = emoji
        label?.font = label!.font.withSize(32)
        label!.textAlignment = .center
        
        addSubview(label!)
    }
    
    func TypeEmoji () {
        viewController?.TypeEmoji(emoji: emoji)
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
        let numberOfIcons: CGFloat = emojiView!.areFavoriteEmpty() ? 9 : 10
        let itemSize: CGFloat = frame.height
        let spacing: CGFloat = (frame.width - numberOfIcons * itemSize)/(numberOfIcons+1.0)
        
        
        for i in 0..<Int(numberOfIcons) {
            let button = UIButton(frame: CGRect(x: spacing * (1+CGFloat(i))+itemSize*CGFloat(i), y: 0, width: itemSize, height: itemSize))
            button.setImage(getIcon(index: i).withRenderingMode(.alwaysTemplate), for: .normal)
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
    
    func getIcon (index: Int) -> UIImage {
        let i = emojiView!.areFavoriteEmpty() ? index+1 : index
        
        if i == 0 {
            return UIImage(systemName: "heart")!
        } else if i == 1 {
            return UIImage(named: "ic_smileys_people")!
        } else if i == 2 {
            return UIImage(systemName: "hand.wave")!
        } else if i == 3 {
            return UIImage(named: "ic_animals_nature")!
        } else if i == 4 {
            return UIImage(named: "ic_food_drink")!
        } else if i == 5 {
            return UIImage(named: "ic_travel_places")!
        } else if i == 6 {
            return UIImage(named: "ic_activity")!
        } else if i == 7 {
            return UIImage(named: "ic_objects")!
        } else if i == 8 {
            return UIImage(named: "ic_symbols")!
        } else if i == 9 {
            return UIImage(named: "ic_flags")!
        }
        return UIImage(named: "ic_flags")!
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
