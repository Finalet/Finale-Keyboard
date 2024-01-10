//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Grant Oganyan on 1/31/22.
//

import UIKit
import SwiftUI
import Foundation
import ElegantEmojiPicker

class FinaleKeyboard: UIInputViewController {
    private weak var _heightConstraint: NSLayoutConstraint?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard nil == _heightConstraint else { return }

        // We must add a subview with an `instrinsicContentSize` that uses autolayout to force the height constraint to be recognized.
        
        let emptyView = UILabel(frame: .zero)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)

        _heightConstraint = view.heightAnchor.constraint(equalToConstant: FinaleKeyboard.buttonHeight*3)
        _heightConstraint?.priority = .required - 1
        _heightConstraint?.isActive = true
        
        CheckAutoCapitalization()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
            _heightConstraint?.constant = FinaleKeyboard.buttonHeight*3
        } else {
            _heightConstraint?.constant = FinaleKeyboard.buttonHeight*2
        }
    }
    
    static var instance: FinaleKeyboard!
    
    static let buttonHeight: CGFloat = 60.0
    let emojiRowHeight = 38.0
    
    var emojiSearchRow: EmojiSearchRow?
    var keysView = UIView()
    var keysViewTopConstraint: NSLayoutConstraint?
    var keysViewBottomConstraint: NSLayoutConstraint?
    var middleRowStrip = UIView()
    
    var emojiView = EmojiView()
    
    var characterButtons: Dictionary<String, CharacterButton> = [String:CharacterButton]()
    var leadingBottomButton: FunctionButton = FunctionButton(.Shift)
    var trailingBottomButton: FunctionButton = FunctionButton(.Backspace)
    
    static var isShift = false
    static var isCaps = false
    static var isAutoCorrectOn = true
    static var isAutoCorrectGrammarOn = true
    static var isAutoCapitalizeOn = true
    static var isTypingHapticEnabled = false
    static var isGesturesHapticEnabled = false
    
    static var currentLocale = Locale.en_US
    static var enabledLocales = [Locale.en_US, Locale.ru_RU]
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
    
    var capsTimer: Timer?
    
    var cursorMoveTimer = Timer()
    var leftEdgeTimer: Timer?
    var rightEdgeTimer: Timer?
    
    var lastTouchPosX = 0.0
    
    var punctuationArray: [String] = []
    var shortcuts: [String:String] = [:]
    var defaultDictionary: Dictionary<String, [String]> = [String:[String]]()
    var userDictionary: [String] = []
    
    var learningWordsDictionary: Dictionary<String, Int> = [String:Int]()
    let learningWordsRepeateThreashold = 3
    var autoLearnWords = true
    
    // Dynamic tap zones
    static var isDynamicTapZonesEnabled: Bool = false
    static var isDynamicTapZonesDisplayEnabled: Bool = false
    static var maxDynamicTapZoneScale = 0.4
    static var dynamicTapZoneProbabilityMultiplier = 1.0
    let minNgram = 1
    let maxNgram = 5
    
    let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FinaleKeyboard.instance = self
        LoadPreferences()
        InitKeysView()
        BuildKeyboardView(viewType: .Characters)
        BuildEmojiView()
        SuggestionsView()
        InitSuggestionsArray()
        InitDictionary()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SaveLearningWordsDictionary()
        ReleaseMemory()
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
        
        userDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_userDictionary") as? [String] ?? [String]()
        autoLearnWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autoLearnWords") as? Bool ?? true
        if autoLearnWords {
            learningWordsDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_learningWordsDictionary") as?  Dictionary<String, Int> ?? [String:Int]()
        }
    }
    
    func SaveUserDictionary () {
        userDefaults?.setValue(userDictionary, forKey: "FINALE_DEV_APP_userDictionary")
    }
    func SaveLearningWordsDictionary () {
        userDefaults?.setValue(learningWordsDictionary, forKey: "FINALE_DEV_APP_learningWordsDictionary")
    }
    
    func LoadPreferences () {
        let EN_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_en_locale_enabled") as? Bool ?? true
        let RU_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_ru_locale_enabled") as? Bool ?? false
        FinaleKeyboard.enabledLocales.removeAll()
        if EN_enabled { FinaleKeyboard.enabledLocales.append(Locale.en_US) }
        if RU_enabled { FinaleKeyboard.enabledLocales.append(Locale.ru_RU) }
        
        FinaleKeyboard.isAutoCorrectOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        FinaleKeyboard.isAutoCorrectGrammarOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        FinaleKeyboard.isAutoCapitalizeOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
        FinaleKeyboard.isTypingHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isTypingHapticEnabled") as? Bool ?? false
        FinaleKeyboard.isGesturesHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isGesturesHapticEnabled") as? Bool ?? true
        FinaleKeyboard.isDynamicTapZonesEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isDynamicTapZonesEnabled") as? Bool ?? false
        FinaleKeyboard.isDynamicTapZonesDisplayEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isDynamicTapZonesDisplayEnabled") as? Bool ?? false
        FinaleKeyboard.maxDynamicTapZoneScale = userDefaults?.value(forKey: "FINALE_DEV_APP_maxDynamicTapZoneScale") as? CGFloat ?? 0.4
        FinaleKeyboard.dynamicTapZoneProbabilityMultiplier = userDefaults?.value(forKey: "FINALE_DEV_APP_dynamicTapZoneProbabilityMultiplier") as? CGFloat ?? 1.5
        
        punctuationArray = userDefaults?.value(forKey: "FINALE_DEV_APP_punctuationArray") as? [String] ?? Defaults.punctuation
        shortcuts = userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String : String] ?? Defaults.shortcuts
        FinaleKeyboard.currentLocale = Locale(rawValue: UserDefaults.standard.integer(forKey: "FINALE_DEV_APP_CurrentLocale")) ?? .en_US
        
        if !FinaleKeyboard.enabledLocales.contains(FinaleKeyboard.currentLocale) {
            FinaleKeyboard.currentLocale = FinaleKeyboard.enabledLocales[0]
        }
    }
    
    func InitSuggestionsArray () {
        for _ in 0..<maxSuggestionHistory {
            suggestionsArrays.append(SuggestionsArray(suggestions: [String](), lastPickedSuggestionIndex: 1, positionIndex: String().startIndex))
        }
    }
    
    func InitKeysView () {
        keysView.backgroundColor = .clear
        self.view.addSubview(keysView, anchors: [.safeAreaLeading(0), .safeAreaTrailing(0)])
        keysViewTopConstraint?.isActive = false
        keysViewTopConstraint = keysView.topAnchor.constraint(equalTo: self.view.topAnchor)
        keysViewTopConstraint?.isActive = true
        keysViewBottomConstraint?.isActive = false
        keysViewBottomConstraint = keysView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        keysViewBottomConstraint?.isActive = true
        
        middleRowStrip.backgroundColor = .gray.withAlphaComponent(0.5)
        keysView.addSubview(middleRowStrip, anchors: [.leading(0), .trailing(0), .centerY(0), .heightMultiplier(0.3333)])
        
        keysView.addSubview(leadingBottomButton, anchors: [.leading(0), .bottom(0)])
        keysView.addSubview(trailingBottomButton, anchors: [.trailing(0), .bottom(0)])
    }
    
    func BuildKeyboardView (viewType: ViewType, updateViewType: Bool = true) {
        if viewType == .Characters {
            BuildKeyboardView(topRow: FinaleKeyboard.currentLocale.topRow, middleRow: FinaleKeyboard.currentLocale.middleRow, bottomRow: FinaleKeyboard.currentLocale.bottomRow)
            leadingBottomButton.ChangeFunction(new: FinaleKeyboard.isCaps ? .Caps : .Shift)
            trailingBottomButton.ChangeFunction(new: .Backspace)
            CheckAutoCapitalization()
        } else if viewType == .Symbols {
            BuildKeyboardView(topRow: Symbols.Symbols.topRow, middleRow: Symbols.Symbols.middleRow, bottomRow: Symbols.Symbols.bottomRow)
            leadingBottomButton.ChangeFunction(new: .SymbolsShift)
            trailingBottomButton.ChangeFunction(new: .Backspace)
        } else if viewType == .ExtraSymbols {
            BuildKeyboardView(topRow: Symbols.ExtraSymbols.topRow, middleRow: Symbols.ExtraSymbols.middleRow, bottomRow: Symbols.ExtraSymbols.bottomRow)
            leadingBottomButton.ChangeFunction(new: .ExtraSymbolsShift)
            trailingBottomButton.ChangeFunction(new: .Backspace)
        }
        if updateViewType { FinaleKeyboard.currentViewType = viewType }
    }
    
    func BuildKeyboardView (topRow: [String], middleRow: [String], bottomRow: [String]) {
        characterButtons.forEach{ $0.value.removeFromSuperview() }
        characterButtons.removeAll()
        
        
        BuildRow(characters: topRow, row: .Top)
        BuildRow(characters: middleRow, row: .Middle, prevRowFirstButton: characterButtons[topRow[0]])
        BuildRow(characters: bottomRow, row: .Bottom, prevRowFirstButton: characterButtons[middleRow[0]])
    }
    
    func BuildRow (characters: [String], row: KeyboardRow, prevRowFirstButton: CharacterButton? = nil) {
        for i in 0..<characters.count {
            let button = CharacterButton(characters[i])
            let prevButton = i != 0 ? characterButtons[characters[i-1]] : nil
            
            var anchors: [LayoutAnchor] = []
            if i == 0 { // The first key is responsible for vertical anchors.
                if row == .Top { anchors.append(.top(0)) }
                else if row == .Bottom { anchors.append(.bottom(0)) }
                
                if let prevRowFirstButton = prevRowFirstButton {
                    anchors.append(contentsOf: [.topToBottom(prevRowFirstButton, 0), .heightToHeight(prevRowFirstButton, 0)])
                }
            }
            keysView.addSubview(button, anchors: anchors)
            
            if let prevButton = prevButton {
                button.widthAnchor.constraint(equalTo: prevButton.widthAnchor).isActive = true
                button.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor).isActive = true
                button.topAnchor.constraint(equalTo: prevButton.topAnchor).isActive = true
                button.bottomAnchor.constraint(equalTo: prevButton.bottomAnchor).isActive = true
            }
            
            if i == 0 {
                if row == .Bottom {
                    button.leadingAnchor.constraint(equalTo: leadingBottomButton.trailingAnchor).isActive = true
                    button.heightAnchor.constraint(equalTo: leadingBottomButton.heightAnchor).isActive = true
                    button.widthAnchor.constraint(equalTo: leadingBottomButton.widthAnchor).isActive = true
                } else {
                    button.leadingAnchor.constraint(equalTo: keysView.leadingAnchor).isActive = true
                }
            } else if i == characters.count - 1 {
                if row == .Bottom {
                    button.trailingAnchor.constraint(equalTo: trailingBottomButton.leadingAnchor).isActive = true
                    button.heightAnchor.constraint(equalTo: trailingBottomButton.heightAnchor).isActive = true
                    button.widthAnchor.constraint(equalTo: trailingBottomButton.widthAnchor).isActive = true
                } else {
                    button.trailingAnchor.constraint(equalTo: keysView.trailingAnchor).isActive = true
                }
            }
            
            characterButtons[characters[i]] = button
        }
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
        label.heightAnchor.constraint(equalToConstant: FinaleKeyboard.buttonHeight * 0.4).isActive = true
        
        view.addSubview(label)
        return label
    }
    
    func BuildEmojiView () {
        self.view.addSubview(emojiView, anchors: [.topToBottom(keysView, 0), .leading(0), .trailing(0), .heightToHeight(self.view, 0)])
    }
    
    func OpenEmoji () {
        emojiView.ResetView()
        ResetSuggestionsLabels()
        keysViewTopConstraint?.constant = -self.view.frame.height
        keysViewBottomConstraint?.constant = -self.view.frame.height
        lastViewType = FinaleKeyboard.currentViewType
        FinaleKeyboard.currentViewType = .Emoji
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
        }
    }
    
    func CloseEmoji (hideEmojiSearchRow: Bool = false) {
        keysViewTopConstraint?.constant = (emojiSearchRow == nil || hideEmojiSearchRow) ? 0 : emojiRowHeight
        keysViewBottomConstraint?.constant = 0
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            if hideEmojiSearchRow {
                self.emojiSearchRow?.removeFromSuperview()
                self.emojiSearchRow = nil
            }
        }
        if FinaleKeyboard.currentViewType != .SearchEmoji {
            FinaleKeyboard.currentViewType = lastViewType
            RedrawSuggestionsLabels()
        }
    }
    
    func ToggleSearchEmojiView () {
        var hideEmojiSearchRow = false
        if FinaleKeyboard.currentViewType != .SearchEmoji {
            FinaleKeyboard.currentViewType = .SearchEmoji
            
            emojiSearchRow?.removeFromSuperview()
            emojiSearchRow = EmojiSearchRow()
            
            self.view.addSubview(emojiSearchRow!, anchors: [.safeAreaLeading(0), .safeAreaTrailing(0), .bottomToTop(keysView, 0), .height(emojiRowHeight)])
            
        } else {
            hideEmojiSearchRow = true
            
            FinaleKeyboard.currentViewType = .Characters
        }
        
        CloseEmoji(hideEmojiSearchRow: hideEmojiSearchRow)
        HapticFeedback.GestureImpactOccurred()
    }
    
    func TypeCharacter (_ character: String) {
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.TypeChar(character)
            return
        }
        
        var shouldPlaceBeforeSpace = false
        if character == "\"" {
            let count = self.textDocumentProxy.documentContextBeforeInput?.filter { $0 == Character(character) }.count ?? 0
            if count % 2 != 0 {
                shouldPlaceBeforeSpace = true
            }
        } else if character == ")" {
            shouldPlaceBeforeSpace = true
        }
        
        var x = false
        if (shouldPlaceBeforeSpace) {
            if (FinaleKeyboard.isAutoCorrectOn && getLastChar() == " ") {
                self.textDocumentProxy.deleteBackward()
                x = true
            }
        }
        
        self.textDocumentProxy.insertText(shouldCapitalize ? character.capitalized : character)
        FadeoutSuggestions()
        
        if (x) { self.textDocumentProxy.insertText(" ") }
        
        CheckAutoCapitalization()
        ProcessDynamicTapZones()
    }
    func TypeEmoji (emoji: String) {
        if (getOneBeforeLastChar() != "" && Character(getOneBeforeLastChar()).isEmoji && getLastChar() == " ") {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.insertText(emoji)
        self.textDocumentProxy.insertText(" ")
    }
    
    func BackAction() {
        if FinaleKeyboard.currentViewType == .SearchEmoji {
            ToggleSearchEmojiView()
            RedrawSuggestionsLabels()
        }
    }
    
    func BackspaceAction () {
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.BackspaceAction()
            return
        }
        
        self.textDocumentProxy.deleteBackward()
        CheckAutoCapitalization()
        ProcessDynamicTapZones()
    }
    
    func ShowShortcutPreviews () {
        characterButtons.forEach {
            $0.value.ShowShortcutPreview()
        }
    }
    func HideShortcutPreviews () {
        characterButtons.forEach {
            $0.value.HideShortcutPreview()
        }
    }
    
    func ToggleAutoCorrect () {
        FinaleKeyboard.isAutoCorrectOn.toggle()
        userDefaults?.setValue(FinaleKeyboard.isAutoCorrectOn, forKey: "FINALE_DEV_APP_autocorrectWords")
        
        self.ShowNotification(text: FinaleKeyboard.isAutoCorrectOn ? "Autocorrection on" : "Autocorrection off")
        
        HapticFeedback.GestureImpactOccurred()
    }
    
    func StartMoveCursor (touchLocation: CGPoint) {
        self.lastTouchPosX = touchLocation.x
        
        UIView.animate (withDuration: 0.3) {
            self.keysView.alpha = 0.5
        }
        
        HapticFeedback.GestureImpactOccurred()
    }
    
    func EndMoveCursor () {
        UIView.animate (withDuration: 0.3) {
            self.keysView.alpha = 1
        }
        ProcessDynamicTapZones()
    }
    
    func MoveCursor (touchLocation: CGPoint) {
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
        if capsTimer != nil {
            capsTimer?.invalidate()
            capsTimer = nil
            CapsAction()
        } else {
            capsTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                self.capsTimer = nil
            }
            
            if FinaleKeyboard.isCaps {
                FinaleKeyboard.isCaps = false
                FinaleKeyboard.isShift = false
                leadingBottomButton.ChangeFunction(new: .Shift)
            } else {
                FinaleKeyboard.isShift.toggle()
            }
        }
        
        UpdateButtonsTitles()
    }
    func CapsAction (){
        FinaleKeyboard.isShift = false
        FinaleKeyboard.isCaps = true
        leadingBottomButton.ChangeFunction(new: .Caps)
        UpdateButtonsTitles()
    }
    func ReturnAction () {
        self.textDocumentProxy.insertText("\n")
        ResetSuggestions()
        CheckAutoCapitalization()
    }
    
    func SwipeRight () {
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.SwipeRight()
            return
        }
        
        if self.textDocumentProxy.documentContextBeforeInput == nil {
            ResetSuggestionsLabels()
            pickedPunctuationIndex = 0
            InsertPunctuation(index: pickedPunctuationIndex)
        } else if self.textDocumentProxy.documentContextBeforeInput?.last != " " {
            ResetSuggestionsLabels()
            if (FinaleKeyboard.isAutoCorrectOn) {
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
                index = punctuationArray.firstIndex(of: getOneBeforeLastChar())!
            } else {
                ResetSuggestionsLabels()
            }
            
            InsertPunctuation(index: index)
        }
        CheckAutoCapitalization()
        ResetDynamicTapZones()
        if FinaleKeyboard.currentViewType != .Characters { BuildKeyboardView(viewType: .Characters) }
    }
    func SwipeDown () {
        if FinaleKeyboard.currentViewType == .SearchEmoji { return }
        if !self.textDocumentProxy.hasText { return }
        
        if canEditPrevPunctuation {
            if (pickedPunctuationIndex < punctuationArray.count-1) {
                pickedPunctuationIndex += 1
                EditPreviousPunctuation()
            }
            return
        }
        
        if isPunctuation(char: getOneBeforeLastChar()) && isPunctuation(char: getLastChar()) {
            if (pickedPunctuationIndex < punctuationArray.count-1) {
                pickedPunctuationIndex += 1
                ReplacePunctiation()
            }
            return
        }
        
        EditPreviousWord(upOrDown: -1)
    }
    func SwipeUp () {
        if FinaleKeyboard.currentViewType == .SearchEmoji { return }
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
        let isCaps = lastWord.uppercased() == lastWord
        
        let checker = UITextChecker()
        let misspelledRange = checker.rangeOfMisspelledWord(in: !isCaps ? lastWord : lastWord.lowercased(), range: NSMakeRange(0, lastWord.count), startingAt: 0, wrap: true, language: "\(FinaleKeyboard.currentLocale)")
       
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
            suggestionsArrays[nextSuggestionArray].suggestions.append(contentsOf: checker.guesses(forWordRange: misspelledRange, in: lastWord, language: "\(FinaleKeyboard.currentLocale)") ?? [String]())
            while suggestionsArrays[nextSuggestionArray].suggestions.count > maxSuggestions { suggestionsArrays[nextSuggestionArray].suggestions.removeLast() }
        }
        
        nextSuggestionArray = (nextSuggestionArray+1) % maxSuggestionHistory
    }
    
    func AppendSuggestionFromDictionary (dict: Dictionary<String, [String]>, lastWord: String) {
        if !FinaleKeyboard.isAutoCorrectGrammarOn { return }
        
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
            var originalInput = ""
            while self.textDocumentProxy.hasText && self.textDocumentProxy.documentContextBeforeInput?.last != " " {
                if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput?.last == nil) { break }
                originalInput.insert(self.textDocumentProxy.documentContextBeforeInput?.last ?? Character(""), at: originalInput.startIndex)
                self.textDocumentProxy.deleteBackward()
            }
            let isCaps = originalInput.uppercased() == originalInput
            self.textDocumentProxy.insertText(!isCaps ? suggestionsArrays[x].suggestions[pickedSuggestionIndex] : suggestionsArrays[x].suggestions[pickedSuggestionIndex].uppercased())
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
        while self.textDocumentProxy.documentContextBeforeInput != "" && self.textDocumentProxy.documentContextBeforeInput != nil && getLastChar() != " " {
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
        self.textDocumentProxy.insertText(punctuationArray[pickedPunctuationIndex])
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
        HapticFeedback.GestureImpactOccurred()
        
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.Delete()
            return
        }
        
        let x = getCorrectSuggestionArrayIndex()
        self.textDocumentProxy.deleteBackward()
        
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
        ProcessDynamicTapZones()
        canEditPrevPunctuation = false
    }
    func InsertPunctuation (index: Int) {
        pickedPunctuationIndex = index
        lastPickedPunctuationIndex = index
        UpdateSuggestionsLabelsPunctuation()
        AnimateSuggestionLabels(index: pickedPunctuationIndex, instant: true)
        
        self.textDocumentProxy.deleteBackward()
        self.textDocumentProxy.insertText(String(punctuationArray[index]) + " ")
        
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
    
    func UpdateButtonsTitles () {
        characterButtons.forEach { $0.value.ToggleCapitalization(shouldCapitalize) }
        if leadingBottomButton.function == .Shift || leadingBottomButton.function == .Caps {
            leadingBottomButton.ToggleHighlight(shouldCapitalize)
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
        suggestionLabels.forEach {
            $0.text = ""
            $0.textColor = .gray
        }
        centerXConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    
    func RedrawSuggestionsLabels () {
        if isPunctuation(char: getOneBeforeLastChar()) {
            pickedPunctuationIndex = punctuationArray.firstIndex(of: getOneBeforeLastChar())!
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
        guard self.suggestionLabels.indices.contains(index) else { return }
        
        self.view.layoutIfNeeded()
        let deltaX = self.suggestionLabels[index].frame.origin.x + self.suggestionLabels[index].frame.width*0.5 - UIScreen.main.bounds.width*0.5
        centerXConstraint.constant -= deltaX
        UIView.animate(withDuration: instant ? 0 : 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    func UpdateSuggestionsLabelsPunctuation () {
        for i in 0..<suggestionLabels.count {
            if punctuationArray.count > i {
                suggestionLabels[i].text = punctuationArray[i]
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
    
    @discardableResult
    func CheckAutoCapitalization () -> Bool {
        if !FinaleKeyboard.isAutoCapitalizeOn { return false }
        
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
        FinaleKeyboard.isShift = true
        UpdateButtonsTitles()
    }
    func RemoveShift () {
        FinaleKeyboard.isShift = false
        UpdateButtonsTitles()
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        CheckAutoCapitalization()
        if (!self.textDocumentProxy.hasText) { RedrawSuggestionsLabels() }
    }
    
    func MiddleRowReactAnimation () {
        UIView.animate(withDuration: 0.17, delay: 0, options: .allowUserInteraction) {
            self.middleRowStrip.backgroundColor = self.middleRowStrip.backgroundColor?.withAlphaComponent(0.6)
        } completion: { _ in
            UIView.animate(withDuration: 0.17, delay: 0, options: .allowUserInteraction) {
                self.middleRowStrip.backgroundColor = self.middleRowStrip.backgroundColor?.withAlphaComponent(0.5)
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
        return punctuationArray.contains(char)
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
    func getStringBeforeCursor(length: Int) -> String? {
        if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput == "") { return nil }
        let text: String = self.textDocumentProxy.documentContextBeforeInput!
        return String(text[text.index(text.endIndex, offsetBy: -min(length, text.count))..<text.endIndex])
    }
    
    func ToggleLocale () {
        let index = ((FinaleKeyboard.enabledLocales.firstIndex(of: FinaleKeyboard.currentLocale) ?? 0) + 1) % FinaleKeyboard.enabledLocales.count
        FinaleKeyboard.currentLocale = FinaleKeyboard.enabledLocales[index]
        
        BuildKeyboardView(viewType: .Characters, updateViewType: false)
        ResetSuggestions()
        
        UserDefaults.standard.set(FinaleKeyboard.currentLocale.rawValue, forKey: "FINALE_DEV_APP_CurrentLocale")
    }
    func ToggleSymbolsView () {
        if FinaleKeyboard.currentViewType == .Characters { BuildKeyboardView(viewType: .Symbols) }
        else if FinaleKeyboard.currentViewType == .Symbols || FinaleKeyboard.currentViewType == .ExtraSymbols { BuildKeyboardView(viewType: .Characters) }
    }
    func ToggleExtraSymbolsView () {
        if FinaleKeyboard.currentViewType == .Symbols { BuildKeyboardView(viewType: .ExtraSymbols) }
        else if FinaleKeyboard.currentViewType == .ExtraSymbols { BuildKeyboardView(viewType: .Symbols) }
    }
    
    var shouldCapitalize: Bool {
        return FinaleKeyboard.isShift || FinaleKeyboard.isCaps
    }
    
    func ReleaseMemory () {
        FinaleKeyboard.instance = nil
        
        suggestionsArrays.removeAll()

        suggestionLabels.forEach { $0.removeFromSuperview() }
        suggestionLabels.removeAll()

        characterButtons.forEach { $0.value.removeFromSuperview() }
        characterButtons.removeAll()

        emojiSearchRow?.removeFromSuperview()
        emojiSearchRow = nil
        keysView.removeFromSuperview()
        middleRowStrip.removeFromSuperview()
        leadingBottomButton.removeFromSuperview()
        trailingBottomButton.removeFromSuperview()
        
        emojiView.pageControl.removeFromSuperview()
        emojiView.emojiSections.removeAll()
        (emojiView.masterCollection.visibleCells as? [EmojiCollectionCell])?.forEach {
            $0.emojiSection = nil
            $0.collectionView.removeFromSuperview()
        }
        emojiView.masterCollection.removeFromSuperview()
        emojiView.removeFromSuperview()

        punctuationArray = []
        shortcuts = [:]
        defaultDictionary = [:]
        userDictionary = []
        learningWordsDictionary = [:]
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
}
