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

        _heightConstraint = view.heightAnchor.constraint(equalToConstant: FinaleKeyboard.rowHeight * FinaleKeyboard.rowsNumber)
        _heightConstraint?.priority = .required - 1
        _heightConstraint?.isActive = true
        
        CheckAutoCapitalization()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _heightConstraint?.constant = FinaleKeyboard.rowHeight * FinaleKeyboard.rowsNumber
    }
    
    static var instance: FinaleKeyboard!
    
    static var rowHeight: CGFloat { return (UIScreen.main.bounds.width < UIScreen.main.bounds.height ? 60 : 40) * (FinaleKeyboard.isSpacebarEnabled ? 0.9 : 1) * keyboardHeightMultiplier }
    static var rowsNumber: CGFloat { return FinaleKeyboard.isSpacebarEnabled ? 4 : 3 }
    static let emojiRowHeight = 38.0
    static var keyboardHeightMultiplier: CGFloat = 1.0
    
    var emojiSearchRow: EmojiSearchRow?
    var keysView = UIView()
    var keysViewTopConstraint: NSLayoutConstraint?
    var keysViewBottomConstraint: NSLayoutConstraint?
    var middleRowStrip = UIView()
    
    var emojiView = EmojiView()
    
    var characterButtons: Dictionary<String, CharacterButton> = [String:CharacterButton]()
    var leadingBottomButton: FunctionButton = FunctionButton(.Shift)
    var trailingBottomButton: FunctionButton = FunctionButton(.Backspace)
    
    var toggleSymbolsButton: FunctionButton? = nil
    var toggleEmojiButton: FunctionButton? = nil
    var spaceButton: SpacebarButton? = nil
    var returnButton: ReturnButton? = nil
    
    static var isShift = false
    static var isCaps = false
    static var isAutoCorrectOn = true
    static var isAutoCorrectGrammarOn = true
    static var isAutoCapitalizeOn = true
    static var isTypingHapticEnabled = true
    static var isGesturesHapticEnabled = true
    static var isSpacebarEnabled = false
    static var isSpacebarAutocorrectOn = false
    static var isExperimentalAutocorrectOn = false
    
    static var currentLocale = Locale.en_US
    static var enabledLocales = [Locale.en_US]
    static var currentViewType = ViewType.Characters
    
    var pickedPunctuationIndex = 0
    var lastPickedPunctuationIndex = 0
    
    var suggestionsArrays = [SuggestionsArray]()
    var maxSuggestionHistory = 5
    var nextSuggestionArray = 0
    var suggestionLabels = [UILabel]()
    var maxSuggestions = 7
    var pickedSuggestionIndex = 0
    
    let SuggestionManager = SuggestionsManager()
    
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
    static var showTouchZones: Bool = false
    static var maxTouchZoneScale = 0.3
    static var dynamicTapZoneProbabilityMultiplier = 1.5
    static var dynamicKeyHighlighting = false
    let minNgram = 1
    let maxNgram = 5
    
    let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
    var spellChecker: SpellCheck?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FinaleKeyboard.instance = self
        LoadPreferences()
        InitKeysView()
        BuildKeyboardView(viewType: .Characters)
        BuildEmojiView()
        BuildSuggestionViews()
        InitSuggestionsArray()
        InitDictionary()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SaveLearningWordsDictionary()
    }
    
    func InitDictionary () {
        requestSupplementaryLexicon(completion: { l in
            for i in 0..<l.entries.count {
                self.defaultDictionary[l.entries[i].userInput] = [l.entries[i].documentText]
            }
            
            let data = (try? Data(contentsOf: Bundle.main.url(forResource: "DefaultDictionary", withExtension: "json")!))!
            var entries = try! JSONDecoder().decode([DictionaryItem].self, from: data)
            
            if FinaleKeyboard.isExperimentalAutocorrectOn {
                entries = entries.suffix(4)
            }
            
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
        let ES_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_es_locale_enabled") as? Bool ?? false
        let DE_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_de_locale_enabled") as? Bool ?? false
        FinaleKeyboard.enabledLocales.removeAll()
        if EN_enabled { FinaleKeyboard.enabledLocales.append(Locale.en_US) }
        if RU_enabled { FinaleKeyboard.enabledLocales.append(Locale.ru_RU) }
        if ES_enabled { FinaleKeyboard.enabledLocales.append(Locale.es_ES) }
        if DE_enabled { FinaleKeyboard.enabledLocales.append(Locale.de_DE) }
        
        FinaleKeyboard.isAutoCorrectOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        FinaleKeyboard.isAutoCorrectGrammarOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        FinaleKeyboard.isAutoCapitalizeOn = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
        FinaleKeyboard.isTypingHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isTypingHapticEnabled") as? Bool ?? true
        FinaleKeyboard.isGesturesHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isGesturesHapticEnabled") as? Bool ?? true
        FinaleKeyboard.isSpacebarEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isSpacebarEnabled") as? Bool ?? false
        FinaleKeyboard.isSpacebarAutocorrectOn = userDefaults?.value(forKey: "FINALE_DEV_APP_spacebarAutocorrect") as? Bool ?? false
        FinaleKeyboard.isExperimentalAutocorrectOn = userDefaults?.value(forKey: "FINALE_DEV_APP_isExperimentalAutocorrectOn") as? Bool ?? false
        FinaleKeyboard.isDynamicTapZonesEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isDynamicTapZonesEnabled") as? Bool ?? false
        FinaleKeyboard.showTouchZones = userDefaults?.value(forKey: "FINALE_DEV_APP_showTouchZones") as? Bool ?? false
        FinaleKeyboard.maxTouchZoneScale = userDefaults?.value(forKey: "FINALE_DEV_APP_maxTouchZoneScale") as? CGFloat ?? 0.6
        FinaleKeyboard.dynamicTapZoneProbabilityMultiplier = userDefaults?.value(forKey: "FINALE_DEV_APP_dynamicTapZoneProbabilityMultiplier") as? CGFloat ?? 1.5
        FinaleKeyboard.dynamicKeyHighlighting = userDefaults?.value(forKey: "FINALE_DEV_APP_dynamicKeyHighlighting") as? Bool ?? false
        FinaleKeyboard.keyboardHeightMultiplier = userDefaults?.value(forKey: "FINALE_DEV_APP_keyboardHeightMultiplier") as? CGFloat ?? 1.0
        
        punctuationArray = userDefaults?.value(forKey: "FINALE_DEV_APP_punctuationArray") as? [String] ?? Defaults.punctuation
        shortcuts = userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String : String] ?? Defaults.shortcuts
        var currentLocale = Locale(rawValue: UserDefaults.standard.integer(forKey: "FINALE_DEV_APP_CurrentLocale")) ?? .en_US
        
        if !FinaleKeyboard.enabledLocales.contains(currentLocale) {
            currentLocale = FinaleKeyboard.enabledLocales[0]
        }
        
        SetLocale(currentLocale)
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
        keysView.addSubview(middleRowStrip, anchors: [.leading(0), .trailing(0), .centerYMultiplier(FinaleKeyboard.isSpacebarEnabled ? 0.75 : 1), .heightMultiplier(!FinaleKeyboard.isSpacebarEnabled ? 0.3333 : 0.25)])
        
        keysView.addSubview(leadingBottomButton, anchors: [.leading(0), !FinaleKeyboard.isSpacebarEnabled ? .bottom(0) : nil])
        keysView.addSubview(trailingBottomButton, anchors: [.trailing(0), !FinaleKeyboard.isSpacebarEnabled ? .bottom(0) : nil])
        
        if FinaleKeyboard.isSpacebarEnabled { BuildSpaceRow() }
    }
    
    func BuildKeyboardView (viewType: ViewType, updateViewType: Bool = true) {
        if viewType == .Characters {
            BuildKeyboardView(topRow: FinaleKeyboard.currentLocale.topRow, middleRow: FinaleKeyboard.currentLocale.middleRow, bottomRow: FinaleKeyboard.currentLocale.bottomRow)
            leadingBottomButton.ChangeFunction(new: FinaleKeyboard.isCaps ? .Caps : .Shift)
            toggleSymbolsButton?.ChangeFunction(new: .SymbolsToggle)
            CheckAutoCapitalization()
        } else if viewType == .Symbols {
            BuildKeyboardView(topRow: Symbols.Symbols.topRow, middleRow: Symbols.Symbols.middleRow, bottomRow: Symbols.Symbols.bottomRow)
            leadingBottomButton.ChangeFunction(new: .SymbolsShift)
            leadingBottomButton.ToggleHighlight(false)
            toggleSymbolsButton?.ChangeFunction(new: .SymbolsToggleBack)
        } else if viewType == .ExtraSymbols {
            BuildKeyboardView(topRow: Symbols.ExtraSymbols.topRow, middleRow: Symbols.ExtraSymbols.middleRow, bottomRow: Symbols.ExtraSymbols.bottomRow)
            leadingBottomButton.ChangeFunction(new: .ExtraSymbolsShift)
            leadingBottomButton.ToggleHighlight(false)
            toggleSymbolsButton?.ChangeFunction(new: .SymbolsToggleBack)
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
                else if row == .Bottom { anchors.append(.bottomToBottom(leadingBottomButton, 0)) }
                
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
    
    func BuildSpaceRow () {
        toggleSymbolsButton = FunctionButton(.SymbolsToggle)
        toggleEmojiButton = FunctionButton(.EmojiToggle)
        spaceButton = SpacebarButton()
        returnButton = ReturnButton()
        
        let sharedAnchors: [LayoutAnchor] = [.bottom(0), .topToBottom(leadingBottomButton, 0), .heightToHeight(leadingBottomButton, 0)]
        
        keysView.addSubview(toggleSymbolsButton!, anchors: [.leading(0), .width(50)] + sharedAnchors)
        keysView.addSubview(toggleEmojiButton!, anchors: [.leadingToTrailing(toggleSymbolsButton!, 0), .widthToWidth(toggleSymbolsButton!, 0)] + sharedAnchors)
        keysView.addSubview(spaceButton!, anchors: [.leadingToTrailing(toggleEmojiButton!, 0)] + sharedAnchors)
        keysView.addSubview(returnButton!, anchors: [.leadingToTrailing(spaceButton!, 0), .widthToWidthMultiplier(toggleSymbolsButton!, 2), .topToBottom(trailingBottomButton, 0), .trailing(0)] + sharedAnchors)
    }
    
    func BuildSuggestionViews () {
        for _ in 0...maxSuggestions-1 {
            suggestionLabels.append(BuildSuggestionView())
        }
        
        centerXConstraint = suggestionLabels[1].centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0)
        centerXConstraint.isActive = true
        for i in 1...maxSuggestions-1 {
            suggestionLabels[i].leadingAnchor.constraint(equalTo: suggestionLabels[i-1].trailingAnchor, constant: UIScreen.main.bounds.width*0.2).isActive = true
        }
    }
    
    func BuildSuggestionView () -> UILabel {
        let label = UILabel(frame: .zero)
        label.textColor = .gray
        label.textAlignment = .center
        label.font = UIFont(name: "Gilroy-Medium", size: 11)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: FinaleKeyboard.rowHeight * 0.4).isActive = true
        
        view.addSubview(label)
        return label
    }
    
    func BuildEmojiView () {
        self.view.addSubview(emojiView, anchors: [.topToBottom(keysView, 0), .leading(0), .trailing(0), .heightToHeight(self.view, 0)])
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
        
        while let contextBeforeInput = self.textDocumentProxy.documentContextBeforeInput, contextBeforeInput != "", let lastChar = getLastChar(), !isPunctuation(char: lastChar) {
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
    
    @discardableResult
    func CheckAutoCapitalization () -> Bool {
        if !FinaleKeyboard.isAutoCapitalizeOn { return false }
        
        guard let context = self.textDocumentProxy.documentContextBeforeInput, !context.isEmpty else {
            ForceShift()
            return true
        }
        
        if (getLastChar()?.isNewline == true) {
            ForceShift()
            return true
        }
        
        if (context.count <= 1) {
            RemoveShift()
            return false
        }
        
        if let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: String(oneBeforeLastChar), ignoreCharacters: [" ", ",", ":", ";"]), getLastChar() == " " {
            ForceShift()
            return true
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
        ProcessDynamicTouchZones()
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
        guard let context = self.textDocumentProxy.documentContextBeforeInput, let lastWord = getLastWord() else { return -1 }
        
        for i in 0..<suggestionsArrays.count {
            if suggestionsArrays[i].positionIndex == context.endIndex {
                for i1 in 0..<suggestionsArrays[i].suggestions.count {
                    if suggestionsArrays[i].suggestions[i1] == lastWord {
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
    func isPunctuation(char: Character) -> Bool {
        return isPunctuation(char: String(char))
    }
    func isPunctuation(char: String, ignoreCharacters: [String]) -> Bool {
        if ignoreCharacters.contains(char) { return false }
        else { return isPunctuation(char: char) }
    }
    
    func SetLocale (_ locale: Locale) {
        FinaleKeyboard.currentLocale = locale
        ReloadSpellChecker(clearCurrent: true)
    }

    func ReloadSpellChecker(clearCurrent: Bool = false) {
        guard FinaleKeyboard.isExperimentalAutocorrectOn else { return }
        
        let locale = FinaleKeyboard.currentLocale
        if clearCurrent { self.spellChecker = nil }

        DispatchQueue.global(qos: .userInitiated).async {
            let newSpellCheck = SpellCheck(locale: locale)
            
            DispatchQueue.main.async {
                guard locale == FinaleKeyboard.currentLocale else { return }
                self.spellChecker = newSpellCheck
            }
        }
    }
    
    var shouldCapitalize: Bool {
        return FinaleKeyboard.isShift || FinaleKeyboard.isCaps
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
