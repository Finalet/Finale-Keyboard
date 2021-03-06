//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Grant Oganan on 1/31/22.
//

import UIKit
import SwiftUI
import Foundation

class KeyboardViewController: UIInputViewController {
    
    @IBOutlet var nextKeyboardButton: UIButton!
    
    private weak var _heightConstraint: NSLayoutConstraint?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard nil == _heightConstraint else { return }

        // We must add a subview with an `instrinsicContentSize` that uses autolayout to force the height constraint to be recognized.
        
        let emptyView = UILabel(frame: .zero)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView);

        let heightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: keyboardHeight)
        heightConstraint.priority = .required - 1
        view.addConstraint(heightConstraint)
        _heightConstraint = heightConstraint
        
        CheckAutoCapitalization()
    }
    
    let keyboardHeight: CGFloat = UIScreen.main.bounds.height/4.7
    let buttonHeight: CGFloat = (UIScreen.main.bounds.height/4.7)/3
    let buttonHeightEmojiSearch: CGFloat = 0.85 * (UIScreen.main.bounds.height/4.7)/3
    var emojiSearchRow: UIView?
    var topRowView: UIView?
    var middleRowView: UIView?
    var bottomRowView: UIView?
    var emojiView: EmojiView?
    var emojiSearchBarLabel: UILabel?
    var emojiSearchResultsContainer: UIView?
    var emojiSearchResultsPlaceholder: UILabel?
    var emojiSearchResults: String = ""
    var emojiSearchCarret: UIView?
    
    var KeyboardButtons = [KeyboardButton]()
    
    static var isShift = false
    static var isCaps = false
    static var isMovingCursor = false
    static var isLongPressing = false
    static var isAutoCorrectOn = true
    static var isAutoCorrectGrammarOn = true
    static var isAutoCapitalizeOn = true
    static var isTypingHapticEnabled = false
    static var isGesturesHapticEnabled = false
    
    static var currentLocale = KeyboardViewController.Locale.en_US
    static var enabledLocales = [KeyboardViewController.Locale.en_US, KeyboardViewController.Locale.ru_RU]
    static var currentViewType = ViewType.Characters
    var lastViewType = ViewType.Characters
    
    var pickedPunctuationIndex = 0
    var lastPickedPunctuationIndex = 0
    
    var suggestionsArrays = [SuggestionsArray]()
    var maxSuggestionHistory = 5
    var nextSuggestionArray = 0
    var suggestionLabels = [UILabel]()
    var maxSuggestions = 7
    var pickedSuggestionIndex = 0
    
    var canEditPrevPunctuation = false
    
    var centerXConstraint = NSLayoutConstraint()
    
    var waitingForSecondTap = false
    var capsTimer = Timer()
    
    let longPressDelay = 0.5
    var waitForLongPress = Timer()
    var deleteTimer = Timer()
    var cursorMoveTimer = Timer()
    var leftEdgeTimer: Timer?
    var rightEdgeTimer: Timer?
    
    var lastTouchPosX = 0.0
    
    var toggledAC = false
    
    var defaultDictionary: Dictionary<String, [String]> = [String:[String]]()
    var userDictionary: [String] = [String]()
    
    var learningWordsDictionary: Dictionary<String, Int> = [String:Int]()
    let learningWordsRepeateThreashold = 3
    var autoLearnWords = true
    
    let suiteName = "group.finale-keyboard-cache"
    let ACSavePath = "FINALE_DEV_APP_autocorrectWords"
    let localeSavePath = "FINALE_DEV_APP_CurrentLocale"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Keeping this cauese Apple requires us to
        self.nextKeyboardButton = UIButton(type: .system)
        
        BuildKeyboardView(viewType: .Characters)
        SuggestionsView()
        InitSuggestionsArray()
        LoadPreferences()
        InitDictionary()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SaveLearningWordsDictionary()
    }
    
    func InitDictionary () {
        requestSupplementaryLexicon(completion: { l in
            for i in 0..<l.entries.count {
                self.defaultDictionary[l.entries[i].userInput] = [l.entries[i].documentText]
            }
            
            let data = (try? Data(contentsOf: Bundle.main.url(forResource: "DefaultDictionary", withExtension: "json")!))!
            let entries = try! JSONDecoder().decode([DictionaryItem].self, from: data)
            
            for i in entries {
                self.defaultDictionary[i.input.lowercased()] = i.suggestions
            }
        })
        
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_userDictionary") as? [String] ?? [String]()
        autoLearnWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autoLearnWords") as? Bool ?? true
        if autoLearnWords {
            learningWordsDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_learningWordsDictionary") as?  Dictionary<String, Int> ?? [String:Int]()
        }
    }
    
    func SaveUserDictionary () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(userDictionary, forKey: "FINALE_DEV_APP_userDictionary")
    }
    func SaveLearningWordsDictionary () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(learningWordsDictionary, forKey: "FINALE_DEV_APP_learningWordsDictionary")
    }
    
    func LoadPreferences () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        let EN_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_en_locale_enabled") as? Bool ?? true
        let RU_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_ru_locale_enabled") as? Bool ?? false
        KeyboardViewController.enabledLocales.removeAll()
        if EN_enabled {KeyboardViewController.enabledLocales.append(KeyboardViewController.Locale.en_US)}
        if RU_enabled {KeyboardViewController.enabledLocales.append(KeyboardViewController.Locale.ru_RU)}
        
        KeyboardViewController.isAutoCorrectOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        KeyboardViewController.isAutoCorrectGrammarOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        KeyboardViewController.isAutoCapitalizeOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
        KeyboardViewController.isTypingHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isTypingHapticEnabled") as? Bool ?? false
        KeyboardViewController.isGesturesHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isGesturesHapticEnabled") as? Bool ?? true
        KeyboardViewController.currentLocale = Locale(rawValue: UserDefaults.standard.integer(forKey: localeSavePath)) ?? .en_US
        
        if !KeyboardViewController.enabledLocales.contains(KeyboardViewController.currentLocale) {
            KeyboardViewController.currentLocale = KeyboardViewController.enabledLocales[0]
        }
    }
    
    func InitSuggestionsArray () {
        for _ in 0..<maxSuggestionHistory {
            suggestionsArrays.append(SuggestionsArray(suggestions: [String](), lastPickedSuggestionIndex: 1, positionIndex: String().startIndex))
        }
    }
    func BuildKeyboardView (viewType: ViewType) {
        if viewType == .Characters {
            BuildKeyboardView(topRow: KeyboardViewController.currentLocale == .en_US ? topRowActions_en : topRowActions_ru, middleRow: KeyboardViewController.currentLocale == .en_US ? middleRowActions_en : middleRowActions_ru, bottomRow: KeyboardViewController.currentLocale == .en_US ? bottomRowActions_en : bottomRowActions_ru)
            CheckAutoCapitalization()
        } else if viewType == .Symbols {
            BuildKeyboardView(topRow: topRowSymbols, middleRow: middleRowSymbols, bottomRow: bottomRowSymbols)
        } else if viewType == .ExtraSymbols {
            BuildKeyboardView(topRow: topRowExtraSymbols, middleRow: middleRowExtraSymbols, bottomRow: bottomRowExtraSymbols)
        } else if viewType == .SearchEmoji {
            BuildKeyboardView(topRow: topRowActions_en, middleRow: middleRowActions_en, bottomRow: bottomRowActionsEmojiSearch_en, emojiSearch: true)
        }
        KeyboardViewController.currentViewType = viewType
    }
    
    func BuildKeyboardView (topRow: [Action], middleRow: [Action], bottomRow: [Action], emojiSearch: Bool = false) {
        let height: CGFloat
        if !emojiSearch { height = buttonHeight } else { height = buttonHeightEmojiSearch }
        
        emojiSearchRow?.removeFromSuperview()
        topRowView?.removeFromSuperview()
        middleRowView?.removeFromSuperview()
        bottomRowView?.removeFromSuperview()
        KeyboardButtons.removeAll()
        
        topRowView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: height))
        topRowView!.backgroundColor = .clear
        middleRowView = UIView(frame: CGRect(x: 0, y: height, width: UIScreen.main.bounds.width, height: height))
        middleRowView!.backgroundColor = .gray.withAlphaComponent(0.5)
        bottomRowView = UIView(frame: CGRect(x: 0, y: 2*height, width: UIScreen.main.bounds.width, height: height))
        bottomRowView!.backgroundColor = .clear
        for i in 0..<topRow.count {
            let buttonWidth: CGFloat = UIScreen.main.bounds.width / CGFloat(topRow.count)
            DrawAction(action: topRow[i], frame: CGRect(x: CGFloat(i)*buttonWidth, y: 0, width: buttonWidth, height: height), subView: topRowView!)
        }
        for i in 0..<middleRow.count {
            let buttonWidth: CGFloat = UIScreen.main.bounds.width / CGFloat(middleRow.count)
            DrawAction(action: middleRow[i], frame: CGRect(x: CGFloat(i)*buttonWidth, y: 0, width: buttonWidth, height: height), subView: middleRowView!)
        }
        for i in 0..<bottomRow.count {
            let buttonWidth: CGFloat = UIScreen.main.bounds.width / CGFloat(bottomRow.count)
            DrawAction(action: bottomRow[i], frame: CGRect(x: CGFloat(i)*buttonWidth, y: 0, width: buttonWidth, height: height), subView: bottomRowView!)
        }
        
        if emojiSearch {
            self.topRowView?.frame.origin.y -= self.view.frame.height
            self.middleRowView?.frame.origin.y -= self.view.frame.height
            self.bottomRowView?.frame.origin.y -= self.view.frame.height
            
            let padding = 8.0
            let rowWidth = UIScreen.main.bounds.width-padding*2
            let halfWidth = rowWidth*0.5-padding
            let emojiRowHeight = self.view.frame.height-height*2.8
            
            emojiSearchRow = UIView(frame: CGRect(x: padding, y: 0, width: rowWidth, height: emojiRowHeight))
            emojiSearchRow?.backgroundColor = .clear
            
            emojiSearchBarLabel = UILabel(frame: CGRect(x: 0, y: padding*0.5, width: halfWidth*0.75, height: emojiRowHeight-padding))
            emojiSearchBarLabel!.text = " "
            emojiSearchBarLabel!.layer.cornerRadius = 8
            emojiSearchBarLabel!.layer.backgroundColor = UIColor.systemGray2.withAlphaComponent(0.3).cgColor
            
            emojiSearchResultsPlaceholder = UILabel(frame: CGRect(x: halfWidth*0.75+padding, y: 0, width: halfWidth*1.25+padding, height: emojiRowHeight))
            emojiSearchResultsPlaceholder!.text = "Search Emoji"
            emojiSearchResultsPlaceholder!.textColor = .systemGray
            
            emojiSearchResultsContainer = UIView(frame: CGRect(x: halfWidth*0.75+padding, y: 0, width: halfWidth*1.25+padding, height: emojiRowHeight))
            
            emojiSearchCarret = UIView(frame: CGRect(x: emojiSearchBarLabel!.intrinsicContentSize.width, y: padding, width: 2, height: emojiRowHeight*0.8-padding))
            emojiSearchCarret?.backgroundColor = .systemGray
            emojiSearchCarret?.layer.cornerRadius = 1
            UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse]) {
                self.emojiSearchCarret?.alpha = 0
            }
            
            
            self.emojiSearchRow?.frame.origin.y -= self.view.frame.height
            emojiSearchRow?.addSubview(emojiSearchResultsContainer!)
            emojiSearchRow?.addSubview(emojiSearchBarLabel!)
            emojiSearchRow?.addSubview(emojiSearchResultsPlaceholder!)
            emojiSearchRow?.addSubview(emojiSearchCarret!)
            
            self.view.addSubview(emojiSearchRow!)
        }
        
        self.view.addSubview(topRowView!)
        self.view.addSubview(middleRowView!)
        self.view.addSubview(bottomRowView!)
    }
    
    func DrawAction(action: Action, frame: CGRect, subView: UIView) {
        let button = KeyboardButton(frame: frame)
        button.action = action
        button.viewController = self
        button.SetupButton()
        subView.addSubview(button)
        subView.bringSubviewToFront(button)
        KeyboardButtons.append(button)
    }
    
    func SuggestionsView () {
        for _ in 0...maxSuggestions-1 {
            suggestionLabels.append(SuggestionView())
        }
        
        centerXConstraint = suggestionLabels[1].centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0)
        centerXConstraint.isActive = true
        for i in 1...maxSuggestions-1 {
            suggestionLabels[i].leadingAnchor.constraint(equalTo: suggestionLabels[i-1].trailingAnchor, constant: UIScreen.main.bounds.width*0.2).isActive = true
        }
    }
    
    func SuggestionView () -> UILabel {
        let label = UILabel(frame: .zero)
        label.textColor = .gray
        label.textAlignment = .center
        label.font = UIFont(name: "Gilroy-Medium", size: 11)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: buttonHeight * 0.4).isActive = true
        
        view.addSubview(label)
        return label
    }
    
    func BuildEmojiSearchView() {
        BuildKeyboardView(viewType: .SearchEmoji)
    }
    
    func BuildEmojiView () {
        emojiView = EmojiView(frame: CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height))
        emojiView!.viewController = self
        
        self.view.addSubview(emojiView!)
    }
    
    func ToggleEmojiView () {
        if KeyboardViewController.currentViewType != .Emoji && KeyboardViewController.currentViewType != .SearchEmoji {
            if emojiView == nil {
                BuildEmojiView()
            }
            emojiView?.ResetView()
            ResetSuggestionsLabels()
            UIView.animate(withDuration: 0.4) {
                self.topRowView?.frame.origin.y -= self.view.frame.height
                self.middleRowView?.frame.origin.y -= self.view.frame.height
                self.bottomRowView?.frame.origin.y -= self.view.frame.height

                self.emojiView?.frame.origin.y -= self.view.frame.height
            }
            lastViewType = KeyboardViewController.currentViewType
            KeyboardViewController.currentViewType = .Emoji
        } else {
            UIView.animate(withDuration: 0.4) {
                if KeyboardViewController.currentViewType != .SearchEmoji {
                    self.topRowView?.frame.origin.y = 0
                    self.middleRowView?.frame.origin.y = self.buttonHeight
                    self.bottomRowView?.frame.origin.y = self.buttonHeight * 2
                    self.emojiView?.frame.origin.y = self.view.frame.height
                } else {
                    self.emojiSearchRow?.frame.origin.y = 0
                    self.topRowView?.frame.origin.y = 0 + self.view.frame.height - self.buttonHeightEmojiSearch*3
                    self.middleRowView?.frame.origin.y = self.buttonHeightEmojiSearch + self.view.frame.height - self.buttonHeightEmojiSearch*3
                    self.bottomRowView?.frame.origin.y = self.buttonHeightEmojiSearch * 2 + self.view.frame.height - self.buttonHeightEmojiSearch*3
                    self.emojiView?.frame.origin.y = self.view.frame.height
                }
            }
            if KeyboardViewController.currentViewType != .SearchEmoji {
                KeyboardViewController.currentViewType = lastViewType
                RedrawSuggestionsLabels()
            }
        }
    }
    
    func UseAction (action: Action) {
        switch action.actionType {
        case .Character: TypeCharacter(char: action.actionTitle)
        case .Function: PerformActionFunction(function: action.functionType)
        }
        
        if action.functionType != .Shift && !CheckAutoCapitalization() {
            KeyboardViewController.isShift = false
            UpdateButtonTitleShift()
        }
    }
    
    func TypeCharacter (char: String) {
        if KeyboardViewController.currentViewType == .SearchEmoji {
            emojiSearchBarLabel!.text?.append(char)
            UpdateEmojiSearch()
            return
        }
        
        var shouldPlaceBeforeSpace = false
        if char == "\"" {
            let count = self.textDocumentProxy.documentContextBeforeInput?.filter { $0 == Character(char) }.count ?? 0
            if count % 2 != 0 {
                shouldPlaceBeforeSpace = true
            }
        } else if char == ")" {
            shouldPlaceBeforeSpace = true
        }
        
        var x = false
        if (shouldPlaceBeforeSpace) {
            if (KeyboardViewController.isAutoCorrectOn && getLastChar() == " ") {
                self.textDocumentProxy.deleteBackward()
                x = true
            }
        }
        
        self.textDocumentProxy.insertText(shouldCapitalize ? char.capitalized : char)
        FadeoutSuggestions()
        
        if (x) { self.textDocumentProxy.insertText(" ") }
    }
    func TypeEmoji (emoji: String) {
        if (getOneBeforeLastChar() != "" && Character(getOneBeforeLastChar()).isEmoji && getLastChar() == " ") {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.insertText(emoji)
        self.textDocumentProxy.insertText(" ")
        
        HapticFeedback.TypingImpactOccured()
    }
    
    func UpdateEmojiSearch () {
        emojiSearchCarret!.frame.origin.x = emojiSearchBarLabel!.intrinsicContentSize.width > emojiSearchBarLabel!.frame.width ? emojiSearchBarLabel!.frame.width : emojiSearchBarLabel!.intrinsicContentSize.width
        var searchTerm = emojiSearchBarLabel!.text
        searchTerm?.removeFirst()
        emojiSearchResults = emojiView!.getEmojiSearchResults(searchTerm: searchTerm!)
        if emojiSearchBarLabel!.text!.isEmpty || emojiSearchBarLabel!.text! == " " { emojiSearchResultsPlaceholder!.text = "Search Emoji" }
        else { emojiSearchResultsPlaceholder!.text = emojiSearchResults.isEmpty ? "No emoji found" : "" }
        
        emojiSearchResultsContainer!.subviews.forEach({ $0.removeFromSuperview() })
        
        for i in 0..<emojiSearchResults.count {
            let emoji = EmojiSearchResultButton(frame: CGRect(x: CGFloat(i)*emojiSearchResultsContainer!.frame.size.height, y: 0, width: emojiSearchResultsContainer!.frame.size.height, height: emojiSearchResultsContainer!.frame.size.height))
            emoji.Setup(viewController: self, emoji: emojiSearchResults[emojiSearchResults.index(emojiSearchResults.startIndex, offsetBy: i)].description)
            emojiSearchResultsContainer?.addSubview(emoji)
        }
    }
    
    func PerformActionFunction (function: FunctionType) {
        switch function {
        case .Shift:
            ShiftAction()
        case .SymbolsShift:
            ToggleExtraSymbolsView()
        case .ExtraSymbolsShift:
            ToggleExtraSymbolsView()
        case .Caps:
            CapsAction()
        case .Backspace:
            BackspaceAction()
        case .Back:
            BackAction()
        case .none:
            print("none")
        }
    }
    
    func BackAction() {
        if KeyboardViewController.currentViewType == .SearchEmoji {
            BuildKeyboardView(viewType: .Characters)
            RedrawSuggestionsLabels()
        }
    }
    
    func BackspaceAction () {
        if KeyboardViewController.currentViewType == .SearchEmoji {
            if emojiSearchBarLabel!.text!.count <= 1 { return }
            emojiSearchBarLabel!.text?.removeLast()
            UpdateEmojiSearch()
            MiddleRowReactAnimation()
            return
        }
        
        self.textDocumentProxy.deleteBackward()
        MiddleRowReactAnimation()
        CheckAutoCapitalization()
    }
    
    func LongPressDelete (backspace: Bool) {
        if (KeyboardViewController.isLongPressing) { return }
        waitForLongPress = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { (_) in
            self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (_) in
                if backspace { self.BackspaceAction() }
                else { self.Delete() }
            }
        }
        KeyboardViewController.isLongPressing = true
    }
    func LongPressCharacter (touchLocation: CGPoint, button: KeyboardButton) {
        if (KeyboardViewController.isLongPressing) { return }
        waitForLongPress = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { (_) in
            KeyboardViewController.isMovingCursor = true
            self.lastTouchPosX = touchLocation.x
            button.HideCallout()
            
            UIView.animate (withDuration: 0.3) {
                self.topRowView?.alpha = 0.5
                self.middleRowView?.alpha = 0.5
                self.bottomRowView?.alpha = 0.5
            }
            
            HapticFeedback.GestureImpactOccured()
        }
        KeyboardViewController.isLongPressing = true
    }
    func LongPressShift (button: KeyboardButton) {
        if (KeyboardViewController.isLongPressing) { return }
        waitForLongPress = Timer.scheduledTimer(withTimeInterval: longPressDelay, repeats: false) { (_) in
            KeyboardViewController.isAutoCorrectOn = !KeyboardViewController.isAutoCorrectOn
            button.HideCallout()
            self.toggledAC = true
            self.ShowNotification(text: KeyboardViewController.isAutoCorrectOn ? "Autocorrection on" : "Autocorrection off")
            
            let userDefaults = UserDefaults(suiteName: self.suiteName)
            userDefaults?.setValue(KeyboardViewController.isAutoCorrectOn, forKey: self.ACSavePath)
            
            HapticFeedback.GestureImpactOccured()
        }
        KeyboardViewController.isLongPressing = true
    }
    func CancelLongPress () {
        KeyboardViewController.isLongPressing = false
        toggledAC = false
        CancelWaitingForLongPress()
        
        if (KeyboardViewController.isMovingCursor) {
            KeyboardViewController.isMovingCursor = false
            UIView.animate (withDuration: 0.3) {
                self.topRowView?.alpha = 1
                self.middleRowView?.alpha = 1
                self.bottomRowView?.alpha = 1
            }
        }
    }
    func CancelWaitingForLongPress () {
        deleteTimer.invalidate()
        waitForLongPress.invalidate()
        rightEdgeTimer?.invalidate()
        rightEdgeTimer = nil
        leftEdgeTimer?.invalidate()
        leftEdgeTimer = nil
    }
    
    func CheckMoveCursor (touchLocation: CGPoint) {
        if touchLocation.x < UIScreen.main.bounds.width * 0.1 {
            if leftEdgeTimer == nil {
                leftEdgeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (_) in
                    self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
                    self.lastTouchPosX = touchLocation.x
                }
                rightEdgeTimer?.invalidate()
                rightEdgeTimer = nil
            }
            return
        } else if touchLocation.x > UIScreen.main.bounds.width * 0.9 {
            if (rightEdgeTimer == nil) {
                rightEdgeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (_) in
                    self.textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
                    self.lastTouchPosX = touchLocation.x
                }
                leftEdgeTimer?.invalidate()
                leftEdgeTimer = nil
            }
            return
        }
        rightEdgeTimer?.invalidate()
        rightEdgeTimer = nil
        leftEdgeTimer?.invalidate()
        leftEdgeTimer = nil
        if touchLocation.x - lastTouchPosX > 5 {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
            lastTouchPosX = touchLocation.x
        } else if touchLocation.x - lastTouchPosX < -5 {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            lastTouchPosX = touchLocation.x
        }
        
    }
    
    func ShiftAction () {
        if !waitingForSecondTap {
            waitingForSecondTap = true
            
            capsTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (_) in
                self.waitingForSecondTap = false
            }
        } else {
            CapsAction()
            waitingForSecondTap = false
            capsTimer.invalidate()
            return
        }
        
        if KeyboardViewController.isCaps {
            KeyboardViewController.isCaps = false
            KeyboardViewController.isShift = false
            CheckAutoCapitalization()
        } else {
            KeyboardViewController.isShift = !KeyboardViewController.isShift
        }
        UpdateButtonTitleShift()
    }
    func CapsAction (){
        KeyboardViewController.isShift = false
        KeyboardViewController.isCaps = true
        UpdateButtonTitleShift()
    }
    func ReturnAction () {
        self.textDocumentProxy.insertText("\n")
        ResetSuggestions()
        CheckAutoCapitalization()
    }
    
    func SwipeRight () {
        if KeyboardViewController.currentViewType == .SearchEmoji {
            emojiSearchBarLabel!.text?.append(" ")
            UpdateEmojiSearch()
            return
        }
        
        
        if self.textDocumentProxy.documentContextBeforeInput == nil {
            ResetSuggestionsLabels()
            pickedPunctuationIndex = 0
            InsertPunctuation(index: pickedPunctuationIndex)
        } else if self.textDocumentProxy.documentContextBeforeInput?.last != " " {
            ResetSuggestionsLabels()
            if (KeyboardViewController.isAutoCorrectOn) {
                GenerateAutocorrections()
                CheckUserDictionary()
                ReplaceWithSuggestion(ignoreSpace: false, instant: true)
            } else {
                self.textDocumentProxy.insertText(" ")
            }
            canEditPrevPunctuation = false
        } else {
            if (self.textDocumentProxy.documentContextBeforeInput!.count < 2) {
                ResetSuggestionsLabels()
                Spacebar()
                canEditPrevPunctuation = false
                return
            }
            
            var index = 1
            if isPunctuation(char: getOneBeforeLastChar()) {
                index = punctiationArray.firstIndex(of: getOneBeforeLastChar())!
            } else {
                ResetSuggestionsLabels()
            }
            
            InsertPunctuation(index: index)
        }
        CheckAutoCapitalization()
        if KeyboardViewController.currentViewType != .Characters { BuildKeyboardView(viewType: .Characters) }
    }
    func SwipeDown () {
        if KeyboardViewController.currentViewType == .SearchEmoji { return }
        if !self.textDocumentProxy.hasText { return }
        
        if canEditPrevPunctuation {
            if (pickedPunctuationIndex < punctiationArray.count-1) {
                pickedPunctuationIndex += 1
                EditPreviousPunctuation()
            }
            return
        }
        
        if isPunctuation(char: getOneBeforeLastChar()) && isPunctuation(char: getLastChar()) {
            if (pickedPunctuationIndex < punctiationArray.count-1) {
                pickedPunctuationIndex += 1
                ReplacePunctiation()
            }
            return
        }
        
        EditPreviousWord(upOrDown: -1)
    }
    func SwipeUp () {
        if KeyboardViewController.currentViewType == .SearchEmoji { return }
        if !self.textDocumentProxy.hasText { return }
        
        if canEditPrevPunctuation {
            if (pickedPunctuationIndex > 0) {
                pickedPunctuationIndex -= 1
                EditPreviousPunctuation()
            }
            return
        }
        
        if isPunctuation(char: getOneBeforeLastChar()) && isPunctuation(char: getLastChar()) {
            if (pickedPunctuationIndex > 0) {
                pickedPunctuationIndex -= 1
                ReplacePunctiation()
            }
            return
        }
        
        EditPreviousWord(upOrDown: 1)
    }
    
    func UseUserDictionary () {
        let x = getCorrectSuggestionArrayIndex()
        if x < 0 { return }
        
        if suggestionsArrays[x].suggestions.count < 2 { return }
        
        if userDictionary.contains(suggestionsArrays[x].suggestions[0].lowercased()) {
            ForgetWord(word: suggestionsArrays[x].suggestions[0].lowercased())
        } else {
            LearnWord(word: suggestionsArrays[x].suggestions[0].lowercased())
        }
    }
    
    func LearnWord (word: String, showNotification: Bool = true) {
        userDictionary.append(word)
        SaveUserDictionary()
        if showNotification { ShowNotification(text: "Learned \"" + word + "\"") }
        if learningWordsDictionary[word] != nil { learningWordsDictionary.removeValue(forKey: word) }
    }
    func ForgetWord (word: String, showNotification: Bool = true) {
        while userDictionary.contains(word) {
            userDictionary.remove(at: userDictionary.firstIndex(of: word)!)
        }
        SaveUserDictionary()
        if showNotification { ShowNotification(text: "Forgot \"" + word + "\"") }
    }
    
    func Spacebar () {
        pickedSuggestionIndex = 0
        InsertPunctuation(index: pickedSuggestionIndex)
    }
    
    func GenerateAutocorrections() {
        if (!self.textDocumentProxy.hasText) { return }
        
        let lastWord = getLastWord()
        let checker = UITextChecker()
        let misspelledRange = checker.rangeOfMisspelledWord(in: lastWord, range: NSMakeRange(0, lastWord.count), startingAt: 0, wrap: true, language: "\(KeyboardViewController.currentLocale)")
       
        if (suggestionsArrays[nextSuggestionArray].suggestions.count != 0) {
            suggestionsArrays[nextSuggestionArray].suggestions.removeAll()
            suggestionsArrays[nextSuggestionArray].lastPickedSuggestionIndex = 1
            suggestionsArrays[nextSuggestionArray].positionIndex = String().startIndex
        }
        suggestionsArrays[nextSuggestionArray].suggestions.append(lastWord)
        suggestionsArrays[nextSuggestionArray].positionIndex = self.textDocumentProxy.documentContextBeforeInput!.endIndex
        suggestionsArrays[nextSuggestionArray].lastPickedSuggestionIndex = 0
        
        AppendSuggestionFromDictionary(dict: defaultDictionary, lastWord: lastWord)
        
        if misspelledRange.location != NSNotFound {
            suggestionsArrays[nextSuggestionArray].suggestions.append(contentsOf: checker.guesses(forWordRange: misspelledRange, in: lastWord, language: "\(KeyboardViewController.currentLocale)") ?? [String]())
            while suggestionsArrays[nextSuggestionArray].suggestions.count > maxSuggestions { suggestionsArrays[nextSuggestionArray].suggestions.removeLast() }
        }
        
        nextSuggestionArray = (nextSuggestionArray+1) % maxSuggestionHistory
    }
    
    func AppendSuggestionFromDictionary (dict: Dictionary<String, [String]>, lastWord: String) {
        if !KeyboardViewController.isAutoCorrectGrammarOn { return }
        
        if (dict[lastWord.lowercased()] != nil) {
            if lastWord.first!.isUppercase {
                for i in dict[lastWord.lowercased()]! {
                    suggestionsArrays[nextSuggestionArray].suggestions.append(i.firstUppercased)
                }
            } else {
                suggestionsArrays[nextSuggestionArray].suggestions.append(contentsOf: dict[lastWord.lowercased()]!)
            }
        }
    }
    
    func CheckUserDictionary () {
        pickedSuggestionIndex = 1
        let x = getCorrectSuggestionArrayIndex()
        if x < 0 { return }
        
        if suggestionsArrays[x].suggestions.count >= 2 {
            if userDictionary.contains(suggestionsArrays[x].suggestions[0].lowercased()) {
                pickedSuggestionIndex = 0
            }
        }
    }
    
    func ReplaceWithSuggestion (ignoreSpace: Bool = false, instant: Bool = false, tryLearnNewWord: Bool = false) {
        let x = getCorrectSuggestionArrayIndex()
        if x < 0 { return }
        
        if ignoreSpace{ self.textDocumentProxy.deleteBackward() }
        
        if (suggestionsArrays[x].suggestions.count > 1) {
            while self.textDocumentProxy.hasText && self.textDocumentProxy.documentContextBeforeInput?.last != " " {
                if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput?.last == nil) { break }
                self.textDocumentProxy.deleteBackward()
            }
            self.textDocumentProxy.insertText(suggestionsArrays[x].suggestions[pickedSuggestionIndex])
            if tryLearnNewWord { TryLearnNewWord(word: suggestionsArrays[x].suggestions[pickedSuggestionIndex].lowercased()) }
        } else { pickedSuggestionIndex = 0 }
        
        self.textDocumentProxy.insertText(" ")
        
        suggestionsArrays[x].positionIndex = self.textDocumentProxy.documentContextBeforeInput!.endIndex
        suggestionsArrays[x].lastPickedSuggestionIndex = pickedSuggestionIndex
        
        UpdateSuggestionsLabels(arrayIndex: x)
        AnimateSuggestionLabels(index: pickedSuggestionIndex, instant: instant)
    }
    
    func EditPreviousWord (upOrDown: Int) {
        var dis = 0
        while self.textDocumentProxy.documentContextBeforeInput != "" && getLastChar() != " " {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            dis += 1
        }
        let x = getCorrectSuggestionArrayIndex()
        if x >= 0 {
            if upOrDown == -1 { //down
                if pickedSuggestionIndex < suggestionsArrays[x].suggestions.count-1 {
                    pickedSuggestionIndex += 1
                    ReplaceWithSuggestion(ignoreSpace: true)
                }
            } else if upOrDown == 1 { //up
                if pickedSuggestionIndex > 0 {
                    pickedSuggestionIndex -= 1
                    ReplaceWithSuggestion(ignoreSpace: true, tryLearnNewWord: autoLearnWords && pickedSuggestionIndex == 0)
                } else {
                    UseUserDictionary ()
                }
            }
        }
        
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: dis)
    }
    
    func TryLearnNewWord (word: String) {
        if userDictionary.contains(word.lowercased()) { return }
        
        if learningWordsDictionary[word] == nil {
            learningWordsDictionary[word] = 1
        } else {
            learningWordsDictionary[word]! += 1
            if learningWordsDictionary[word]! >= learningWordsRepeateThreashold {
                learningWordsDictionary.removeValue(forKey: word)
                LearnWord(word: word, showNotification: false)
            }
        }
    }
    
    func ReplacePunctiation () {
        for _ in 0...1 {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.insertText(punctiationArray[pickedPunctuationIndex])
        self.textDocumentProxy.insertText(" ")
        
        UpdateSuggestionsLabelsPunctuation()
        AnimateSuggestionLabels(index: pickedPunctuationIndex)
        CheckAutoCapitalization()
        
        canEditPrevPunctuation = true
    }
    
    func getLastWord () -> String {
        if (self.textDocumentProxy.documentContextBeforeInput?.count==0 || !self.textDocumentProxy.hasText) {return ""}
        
        var lastSpace = false
        if getLastChar() == " " {
            self.textDocumentProxy.deleteBackward()
            lastSpace = true
        }
        
        var beginning = self.textDocumentProxy.documentContextBeforeInput?.lastIndex(of: " ")
        if beginning == nil {
            beginning = self.textDocumentProxy.documentContextBeforeInput?.startIndex
        } else {
            beginning = self.textDocumentProxy.documentContextBeforeInput?.index((self.textDocumentProxy.documentContextBeforeInput?.lastIndex(of: " "))!, offsetBy: 1)
        }
        
        let output = String(self.textDocumentProxy.documentContextBeforeInput?[beginning!...] ?? "")
        
        if lastSpace { self.textDocumentProxy.insertText(" ") }
        
        return output
    }
    
    func Delete() {
        HapticFeedback.GestureImpactOccured()
        
        if KeyboardViewController.currentViewType == .SearchEmoji {
            emojiSearchBarLabel!.text? = " "
            UpdateEmojiSearch()
            MiddleRowReactAnimation()
            return
        }
        
        let x = getCorrectSuggestionArrayIndex()
        self.textDocumentProxy.deleteBackward()
        
        MiddleRowReactAnimation()
        
        //DeletePunctuation
        if let lastChar = self.textDocumentProxy.documentContextBeforeInput?.last {
            if isPunctuation(char: String(lastChar)) {
                self.textDocumentProxy.deleteBackward()
                if self.textDocumentProxy.hasText { self.textDocumentProxy.insertText(" ") }
                RedrawSuggestionsLabels()
                canEditPrevPunctuation = false
                return
            }
        }
        //Delete Words
        while self.textDocumentProxy.hasText && self.textDocumentProxy.documentContextBeforeInput?.last != " " {
            if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput?.last == nil) { break }
            self.textDocumentProxy.deleteBackward()
        }
        if (x >= 0) {
            suggestionsArrays[x].positionIndex = String().endIndex
            suggestionsArrays[x].suggestions = [String]()
            suggestionsArrays[x].lastPickedSuggestionIndex = 1
            nextSuggestionArray = abs((nextSuggestionArray-1) % maxSuggestionHistory)
        }
        CheckAutoCapitalization()
        RedrawSuggestionsLabels()
        canEditPrevPunctuation = false
    }
    func InsertPunctuation (index: Int) {
        pickedPunctuationIndex = index
        lastPickedPunctuationIndex = index
        UpdateSuggestionsLabelsPunctuation()
        AnimateSuggestionLabels(index: pickedPunctuationIndex, instant: true)
        
        self.textDocumentProxy.deleteBackward()
        self.textDocumentProxy.insertText(String(punctiationArray[index]) + " ")
        
        canEditPrevPunctuation = true
        
        CheckAutoCapitalization()
    }
    
    func EditPreviousPunctuation () {
        var dis = 0
        while self.textDocumentProxy.documentContextBeforeInput != "" && !isPunctuation(char: getLastChar()) {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            dis += 1
        }
        ReplacePunctiation()
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: dis)
    }
    
    func UpdateButtonTitleShift () {
        for button in KeyboardButtons {
            if button.action.functionType == .Shift {
                if (!button.isCalloutShown()) {
                    button.imageView?.tintColor = shouldCapitalize ? .label : .systemGray
                }
                continue
            }
            button.setTitle(shouldCapitalize ? button.currentTitle?.capitalized : button.currentTitle?.lowercased(), for: .normal)
            button.calloutLabel.text = button.titleLabel?.text
        }
    }
    
    func ResetSuggestions () {
        for i in 0..<suggestionsArrays.count {
            suggestionsArrays[i].suggestions.count
            suggestionsArrays[i].suggestions.removeAll()
            suggestionsArrays[i].lastPickedSuggestionIndex = 0
            suggestionsArrays[i].positionIndex = String().endIndex
        }
        pickedSuggestionIndex = 0
        ResetSuggestionsLabels()
    }
    func ResetSuggestionsLabels () {
        for i in suggestionLabels {
            i.text = ""
            i.textColor = .gray
        }
        centerXConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    
    func RedrawSuggestionsLabels () {
        if isPunctuation(char: getOneBeforeLastChar()) {
            pickedPunctuationIndex = punctiationArray.firstIndex(of: getOneBeforeLastChar())!
            UpdateSuggestionsLabelsPunctuation()
            AnimateSuggestionLabels(index: pickedPunctuationIndex, instant: true)
        } else {
            UpdateSuggestionsLabels()
            AnimateSuggestionLabels(index: pickedSuggestionIndex, instant: true)
        }
    }
    
    func ShowNotification (text: String) {
        UIView.animate(withDuration: 0.15) {
            for i in self.suggestionLabels {
                i.alpha = 0
            }
        } completion: { [self] _ in
            ResetSuggestionsLabels()
            suggestionLabels[1].text = text
            suggestionLabels[1].textColor = .label
            UIView.animate(withDuration: 0.3) {
                self.suggestionLabels[1].alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: 0.3, delay: 0.7) {
                    self.suggestionLabels[1].alpha = 0
                } completion: { _ in
                    self.RedrawSuggestionsLabels()
                    UIView.animate(withDuration: 0.15) {
                        for i in self.suggestionLabels {
                            i.alpha = 1
                        }
                    }
                }
            }
        }
    }
    
    func UpdateSuggestionsLabels (arrayIndex: Int = -1) {
        let x = arrayIndex == -1 ? getCorrectSuggestionArrayIndex() : arrayIndex
        if (x < 0) {
            ResetSuggestionsLabels()
            return
        }
        pickedSuggestionIndex = suggestionsArrays[x].lastPickedSuggestionIndex
        
        for i in 0..<suggestionLabels.count {
            if suggestionsArrays[x].suggestions.count > i {
                suggestionLabels[i].text = suggestionsArrays[x].suggestions[i]
            } else {
                suggestionLabels[i].text = ""
            }
        }
        UpdateSuggestionColor(index: pickedSuggestionIndex)
    }
    func AnimateSuggestionLabels (index: Int, instant: Bool = false) {
        self.view.layoutIfNeeded()
        let deltaX = self.suggestionLabels[index].frame.origin.x + self.suggestionLabels[index].frame.width*0.5 - UIScreen.main.bounds.width*0.5
        centerXConstraint.constant -= deltaX
        UIView.animate(withDuration: instant ? 0 : 0.25, delay: 0, options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }
    func UpdateSuggestionsLabelsPunctuation () {
        for i in 0..<suggestionLabels.count {
            if punctiationArray.count > i {
                suggestionLabels[i].text = punctiationArray[i]
            } else {
                suggestionLabels[i].text = ""
            }
        }
        UpdateSuggestionColor(index: pickedPunctuationIndex)
    }
    func UpdateSuggestionColor(index: Int) {
        for i in 0..<suggestionLabels.count {
            if index == i {
                suggestionLabels[i].textColor = .label
                continue
            }
            suggestionLabels[i].textColor = .gray
        }
    }
    func FadeoutSuggestions () {
        if (suggestionLabels[0].textColor.cgColor.alpha <= 0) { return }
        if (suggestionLabels[0].text == "") { return }
        
        for i in self.suggestionLabels {
            UIView.transition(with: i, duration: 0.20, options: .transitionCrossDissolve) {
                i.textColor = i.textColor.withAlphaComponent(i.textColor.cgColor.alpha-0.334)
            }
        }
    }
    
    func CheckAutoCapitalization () -> Bool{
        if !KeyboardViewController.isAutoCapitalizeOn { return false }
        
        if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput == "") {
            ForceShift()
            return true
        }
        
        if (Character(getLastChar()).isNewline) {
            ForceShift()
            return true
        }
        
        if (self.textDocumentProxy.documentContextBeforeInput!.count <= 1) {
            RemoveShift()
            return false
        }
        
        if isPunctuation(char: getOneBeforeLastChar(), ignoreCharacters: [" ", ",", ":", ";"]) {
            if (getLastChar() == " ") {
                ForceShift()
                return true
            }
        }
        RemoveShift()
        return false
    }
    
    func ForceShift () {
        KeyboardViewController.isShift = true
        UpdateButtonTitleShift()
    }
    func RemoveShift () {
        KeyboardViewController.isShift = false
        UpdateButtonTitleShift()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        CheckAutoCapitalization()
        if (!self.textDocumentProxy.hasText) { RedrawSuggestionsLabels() }
    }
    
    func MiddleRowReactAnimation () {
        UIView.animate(withDuration: 0.17, delay: 0, options: .allowUserInteraction) {
            self.middleRowView!.backgroundColor = self.middleRowView!.backgroundColor?.withAlphaComponent(0.57)
        } completion: { _ in
            UIView.animate(withDuration: 0.17, delay: 0, options: .allowUserInteraction) {
                self.middleRowView!.backgroundColor = self.middleRowView!.backgroundColor?.withAlphaComponent(0.5)
            }
        }
        
    }
    
    func getCorrectSuggestionArrayIndex() -> Int {
        if (self.textDocumentProxy.documentContextBeforeInput == nil) { return -1 }
        for i in 0..<suggestionsArrays.count {
            if suggestionsArrays[i].positionIndex == self.textDocumentProxy.documentContextBeforeInput?.endIndex {
                for i1 in 0..<suggestionsArrays[i].suggestions.count {
                    if suggestionsArrays[i].suggestions[i1] == getLastWord() {
                        return i
                    }
                }
            }
        }
        return -1
    }

    func isPunctuation(char: String) -> Bool {
        return punctiationArray.contains(char)
    }
    func isPunctuation (char: String, ignoreCharacters: [String]) -> Bool {
        if ignoreCharacters.contains(char) { return false }
        else { return isPunctuation(char: char) }
    }
    
    func getLastChar() -> String {
        if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput == "") { return ""}
        let text: String = self.textDocumentProxy.documentContextBeforeInput!
        return String(text[text.index(text.endIndex, offsetBy: -1)])
    }
    func getOneBeforeLastChar() -> String {
        if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput == "") { return "" }
        if (self.textDocumentProxy.documentContextBeforeInput!.count < 2) { return "" }
        let text: String = self.textDocumentProxy.documentContextBeforeInput!
        return String(text[text.index(text.endIndex, offsetBy: -2)])
    }
    func getTwoBeforeLastChar() -> String {
        if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput == "") { return "" }
        if (self.textDocumentProxy.documentContextBeforeInput!.count < 3) { return "" }
        let text: String = self.textDocumentProxy.documentContextBeforeInput!
        return String(text[text.index(text.endIndex, offsetBy: -3)])
    }
    
    func ToggleLocale () {
        let index = ((KeyboardViewController.enabledLocales.firstIndex(of: KeyboardViewController.currentLocale) ?? 0) + 1) % KeyboardViewController.enabledLocales.count
        KeyboardViewController.currentLocale = KeyboardViewController.enabledLocales[index]
        
        BuildKeyboardView(viewType: .Characters)
        ResetSuggestions()
        
        UserDefaults.standard.set(KeyboardViewController.currentLocale.rawValue, forKey: self.localeSavePath)
    }
    func ToggleSymbolsView () {
        if KeyboardViewController.currentViewType == .Characters { BuildKeyboardView(viewType: .Symbols); KeyboardViewController.isShift = false; KeyboardViewController.isCaps = false }
        else if KeyboardViewController.currentViewType == .Symbols || KeyboardViewController.currentViewType == .ExtraSymbols { BuildKeyboardView(viewType: .Characters) }
    }
    func ToggleExtraSymbolsView () {
        if KeyboardViewController.currentViewType == .Symbols { BuildKeyboardView(viewType: .ExtraSymbols) }
        else if KeyboardViewController.currentViewType == .ExtraSymbols { BuildKeyboardView(viewType: .Symbols) }
    }
    
    var shouldCapitalize: Bool {
        return KeyboardViewController.isShift || KeyboardViewController.isCaps
    }
    
    struct SuggestionsArray {
        var suggestions: [String]
        var lastPickedSuggestionIndex: Int
        var positionIndex: String.Index
        
        init (suggestions: [String], lastPickedSuggestionIndex: Int, positionIndex: String.Index) {
            self.suggestions = suggestions
            self.lastPickedSuggestionIndex = lastPickedSuggestionIndex
            self.positionIndex = positionIndex
        }
        
        mutating func Reset () {
            self.suggestions.removeAll()
            self.lastPickedSuggestionIndex = 1
        }
    }
    
    public struct Action {
        var actionType: ActionType
        var actionTitle: String
        var functionType: FunctionType
        
        init(type: ActionType, title: String, funcType: FunctionType = .none) {
            self.actionType = type
            self.actionTitle = title
            self.functionType = funcType
        }
    }
    
    enum ActionType {
        case Character
        case Function
    }
    
    enum FunctionType {
        case Shift
        case SymbolsShift
        case ExtraSymbolsShift
        case Backspace
        case Caps
        case Back
        case none
    }
    
    enum ViewType {
        case Characters
        case Symbols
        case ExtraSymbols
        case Emoji
        case SearchEmoji
    }
    
    enum Locale: Int {
        case en_US
        case ru_RU
    }
    struct DictionaryItem: Decodable {
        let input: String
        let suggestions: [String]
    }
}

class EmojiSearchResultButton: UIView {
    
    var viewController: KeyboardViewController?
    var emoji: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func Setup(viewController: KeyboardViewController, emoji: String) {
        self.viewController = viewController
        self.emoji = emoji
        
        let emojiLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        emojiLabel.text = emoji
        emojiLabel.textAlignment = .center
        
        let touch = UILongPressGestureRecognizer(target: self, action: #selector(RegisterPress))
        touch.minimumPressDuration = 0
        self.addGestureRecognizer(touch)
        self.addSubview(emojiLabel)
    }
    
    @objc func RegisterPress (gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began) {
            viewController?.TypeEmoji(emoji: emoji!)
            UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                self.frame.origin.y -= self.frame.size.height*0.3
                self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            } completion: { _ in
                UIView.animate(withDuration: 0.05, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
                    self.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.frame.origin.y = 0
                }
            }
        }
    }
}
