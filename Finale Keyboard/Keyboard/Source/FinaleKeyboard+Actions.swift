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
        FadeoutSuggestions()
        
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
        FadeoutSuggestions()
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
            ResetSuggestionsLabels()
            pickedPunctuationIndex = 0
            InsertPunctuation(index: pickedPunctuationIndex)
        } else if context?.last != " " {
            ResetSuggestionsLabels()
            if (FinaleKeyboard.isAutoCorrectOn) {
                GenerateAutocorrections()
                ReplaceWithSuggestion(ignoreSpace: false, instant: true)
            } else {
                self.textDocumentProxy.insertText(" ")
            }
            canEditPrevPunctuation = false
        } else {
            if ((context?.count ?? 0) < 2) {
                ResetSuggestionsLabels()
                SwipeRightSpacebar()
                canEditPrevPunctuation = false
                return
            }
            
            var index = 1
            
            if let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: oneBeforeLastChar) {
                index = punctuationArray.firstIndex(of: String(oneBeforeLastChar)) ?? 1
            } else {
                ResetSuggestionsLabels()
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
        while !isAtWordStart() {
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
        
        if let lastChar = getLastChar(), let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: lastChar), isPunctuation(char: oneBeforeLastChar) {
            if (pickedPunctuationIndex > 0) {
                pickedPunctuationIndex -= 1
                ReplacePunctiation()
            }
            return
        }
        
        EditPreviousWord(upOrDown: 1)
    }
    
    func SwipeRightSpacebar () {
        pickedSuggestionIndex = 0
        InsertPunctuation(index: pickedSuggestionIndex)
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
        ResetSuggestionsLabels()
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
        ResetSuggestions()
        
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
        ResetSuggestions()
        CheckAutoCapitalization()
        ResetDynamicTouchZones()
        
        if [ViewType.Symbols, ViewType.ExtraSymbols].contains(FinaleKeyboard.currentViewType) {
            ToggleSymbolsView()
        }
    }
    
    func ReturnAction () {
        self.textDocumentProxy.insertText("\n")
        ResetSuggestions()
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
        ReloadSpellChecker()
        if showNotification { ShowNotification(text: "Learned \"" + word + "\"") }
        if learningWordsDictionary[word] != nil { learningWordsDictionary.removeValue(forKey: word) }
    }
    
    func ForgetWord (word: String, showNotification: Bool = true) {
        while userDictionary.contains(word) {
            userDictionary.remove(at: userDictionary.firstIndex(of: word)!)
        }
        SaveUserDictionary()
        ReloadSpellChecker()
        if showNotification { ShowNotification(text: "Forgot \"" + word + "\"") }
    }
}
