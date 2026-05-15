//
//  FinaleKeyboard+Actions.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/14/26.
//

import Foundation
import UIKit

//MARK: Primary
extension FinaleKeyboard {
    
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
        
        FadeSuggestions()
        
        if (x) { self.textDocumentProxy.insertText(" ") }
        
        CheckAutoCapitalization()
        ProcessDynamicTouchZones()
    }
    
    func TypeEmoji (emoji: String) {
        if let oneBeforeLastChar = getOneBeforeLastChar(), oneBeforeLastChar.isEmoji, getLastChar() == " " {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.insertText(emoji)
        self.textDocumentProxy.insertText(" ")
    }
    
    func Cut () {
        guard let selection = self.textDocumentProxy.selectedText else { return }
        
        UIPasteboard.general.string = selection
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
        for _ in 1..<selection.count {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)
        self.textDocumentProxy.deleteBackward()
    }
    
    func Copy () {
        guard let selection = self.textDocumentProxy.selectedText else { return }
        UIPasteboard.general.string = selection
    }
    
    func Paste (text: String? = nil) {
        guard let pasteText = text ?? UIPasteboard.general.string else { return }
        self.textDocumentProxy.insertText(pasteText)
        
        ClearSuggestionLabels()
        CheckAutoCapitalization()
        ProcessDynamicTouchZones()
    }
    
}

// MARK: Swipes
extension FinaleKeyboard {
    
    func SwipeRight () {
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.SwipeRight()
            return
        }
        
        let context = self.textDocumentProxy.documentContextBeforeInput
        if context == nil {
            ClearSuggestionLabels()
            pickedPunctuationIndex = 0
            InsertPunctuation(index: pickedPunctuationIndex)
        } else if context?.last != " " {
            if (FinaleKeyboard.isAutoCorrectOn) {
                Autocorrect()
            } else {
                ClearSuggestionLabels()
                self.textDocumentProxy.insertText(" ")
            }
            canEditPrevPunctuation = false
        } else {
            if ((context?.count ?? 0) < 2) {
                ClearSuggestionLabels()
                InsertPunctuation(index: 0)
                canEditPrevPunctuation = false
                return
            }
            
            var index = 1
            
            if let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: oneBeforeLastChar) {
                index = punctuationArray.firstIndex(of: String(oneBeforeLastChar)) ?? 1
            } else {
                ClearSuggestionLabels()
            }
            
            InsertPunctuation(index: index)
        }
        CheckAutoCapitalization()
        ResetDynamicTouchZones()
        if FinaleKeyboard.currentViewType != .Characters { BuildKeyboardView(viewType: .Characters) }
    }
    
    func SwipeLeft() {
        HapticFeedback.GestureImpactOccurred()
        
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.Delete()
            return
        }
        
        let lastWord = getLastWord()
        
        self.textDocumentProxy.deleteBackward()
        
        //DeletePunctuation
        if let lastChar = getLastChar(), isPunctuation(char: lastChar) {
            self.textDocumentProxy.deleteBackward()
            if self.textDocumentProxy.hasText { self.textDocumentProxy.insertText(" ") }
            RedrawSuggestionsLabels()
            canEditPrevPunctuation = false
            return
        }
        
        //Delete Words
        while !isAtWordStart() {
            self.textDocumentProxy.deleteBackward()
        }
        
        if let lastWord = lastWord {
            suggestionsManager.deleteSuggestions(forWord: lastWord)
        }
        
        CheckAutoCapitalization()
        RedrawSuggestionsLabels()
        ProcessDynamicTouchZones()
        
        canEditPrevPunctuation = false
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
        
        if let lastChar = getLastChar(), let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: lastChar), isPunctuation(char: oneBeforeLastChar) {
            if (pickedPunctuationIndex < punctuationArray.count-1) {
                pickedPunctuationIndex += 1
                ReplacePunctiation()
            }
            return
        }
        
        CycleSuggestionsForLastWord(.next)
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
        
        if let lastChar = getLastChar(), let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: lastChar), isPunctuation(char: oneBeforeLastChar) {
            if (pickedPunctuationIndex > 0) {
                pickedPunctuationIndex -= 1
                ReplacePunctiation()
            }
            return
        }
        
        CycleSuggestionsForLastWord(.previous)
    }
}

//MARK: Views
extension FinaleKeyboard {
    
    func ToggleSymbolsView () {
        if FinaleKeyboard.currentViewType == .Characters { BuildKeyboardView(viewType: .Symbols) }
        else if FinaleKeyboard.currentViewType == .Symbols || FinaleKeyboard.currentViewType == .ExtraSymbols { BuildKeyboardView(viewType: .Characters) }
    }
    
    func ToggleExtraSymbolsView () {
        if FinaleKeyboard.currentViewType == .Symbols { BuildKeyboardView(viewType: .ExtraSymbols) }
        else if FinaleKeyboard.currentViewType == .ExtraSymbols { BuildKeyboardView(viewType: .Symbols) }
    }
    
    func OpenEmoji () {
        FinaleKeyboard.currentViewType = .Emoji
        emojiView.PrepareView()
        ClearSuggestionLabels()
        keysViewTopConstraint?.constant = -self.view.frame.height
        keysViewBottomConstraint?.constant = -self.view.frame.height
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4, options: .curveEaseIn) {
            self.view.layoutIfNeeded()
        }
    }
    
    func CloseEmoji (hideEmojiSearchRow: Bool = false) {
        keysViewTopConstraint?.constant = (emojiSearchRow == nil || hideEmojiSearchRow) ? 0 : FinaleKeyboard.emojiRowHeight
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
            FinaleKeyboard.currentViewType = .Characters
            RedrawSuggestionsLabels()
        }
    }
    
    func ToggleSearchEmojiView () {
        var hideEmojiSearchRow = false
        if FinaleKeyboard.currentViewType != .SearchEmoji {
            FinaleKeyboard.currentViewType = .SearchEmoji
            
            emojiSearchRow?.removeFromSuperview()
            emojiSearchRow = EmojiSearchRow()
            
            self.view.addSubview(emojiSearchRow!, anchors: [.safeAreaLeading(0), .safeAreaTrailing(0), .bottomToTop(keysView, 0), .height(FinaleKeyboard.emojiRowHeight)])
            
            returnButton?.ChangeFunction(new: .Back)
        } else {
            hideEmojiSearchRow = true
            
            FinaleKeyboard.currentViewType = .Characters
            
            returnButton?.ChangeFunction(new: .Return)
        }
        
        CloseEmoji(hideEmojiSearchRow: hideEmojiSearchRow)
        HapticFeedback.GestureImpactOccurred()
    }
    
    func ToggleLocale (backwards: Bool = false) {
        var index = ((FinaleKeyboard.enabledLocales.firstIndex(of: FinaleKeyboard.currentLocale) ?? 0) + (backwards ? -1 : 1)) % FinaleKeyboard.enabledLocales.count
        if index < 0 { index += FinaleKeyboard.enabledLocales.count }
        SetLocale(FinaleKeyboard.enabledLocales[index])
        
        BuildKeyboardView(viewType: .Characters, updateViewType: FinaleKeyboard.currentViewType != .SearchEmoji)
        
        UserDefaults.standard.set(FinaleKeyboard.currentLocale.rawValue, forKey: "FINALE_DEV_APP_CurrentLocale")
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
}

// MARK: Actions
extension FinaleKeyboard {
    
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
    
    func CapsAction() {
        FinaleKeyboard.isShift = false
        FinaleKeyboard.isCaps = true
        leadingBottomButton.ChangeFunction(new: .Caps)
        UpdateButtonsTitles()
    }
    
    func SpacebarAction() {
        if let emojiSearchRow = emojiSearchRow {
            emojiSearchRow.SwipeRight()
            return
        }
        
        self.textDocumentProxy.insertText(" ")
        
        ClearSuggestionLabels()
        CheckAutoCapitalization()
        ResetDynamicTouchZones()
        
        if [ViewType.Symbols, ViewType.ExtraSymbols].contains(FinaleKeyboard.currentViewType) {
            ToggleSymbolsView()
        }
    }
    
    func ReturnAction () {
        self.textDocumentProxy.insertText("\n")
        ClearSuggestionLabels()
        CheckAutoCapitalization()
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
        ProcessDynamicTouchZones()
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
        ProcessDynamicTouchZones()
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
    
    func RecordNewWord (_ word: String) {
        guard FinaleKeyboard.autoLearnWords else { return }
        
        let cleanWord = word.lowercased()
        if userDictionary.contains(cleanWord) { return }
        
        let newValue = (learningWordsDictionary[cleanWord] ?? 0) + 1
        
        if newValue >= learningWordsRepeateThreashold {
            learningWordsDictionary.removeValue(forKey: cleanWord)
            LearnWord(word: cleanWord, showNotification: false)
        } else {
            learningWordsDictionary[cleanWord] = newValue
        }
    }
    
    func ToggleUserDictionary (forWord: String) {
        let cleanWord = forWord.lowercased()
        
        if userDictionary.contains(cleanWord) { ForgetWord(word: cleanWord) }
        else { LearnWord(word: cleanWord) }
    }
    
    func LearnWord (word: String, showNotification: Bool = true) {
        userDictionary.append(word)
        SaveUserDictionary()
        ReloadSpellChecker()
        if showNotification { ShowNotification(text: "Learned \"\(word)\"") }
        learningWordsDictionary.removeValue(forKey: word)
    }
    
    func ForgetWord (word: String, showNotification: Bool = true) {
        userDictionary.removeAll { $0 == word }
        SaveUserDictionary()
        ReloadSpellChecker()
        if showNotification { ShowNotification(text: "Forgot \"\(word)\"") }
    }
}
