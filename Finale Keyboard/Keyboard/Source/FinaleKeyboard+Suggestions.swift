//
//  FinaleKeyboard+Suggestions.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/14/26.
//

import Foundation
import UIKit

// MARK: Suggestions Logic
extension FinaleKeyboard {
    
    func Autocorrect() {
        guard let lastWord = getLastWord() else { return }
        
        let defaultSuggestions: [String] = getDefaultSuggestions(for: lastWord)
        let suggestions: [String] = !FinaleKeyboard.isExperimentalAutocorrectOn ? getStandardSpellcheckSuggestions(for: lastWord) : (spellChecker?.suggestions(forWord: lastWord)?.compactMap({ $0.word }) ?? getStandardSpellcheckSuggestions(for: lastWord))
        var allSuggestions = defaultSuggestions + suggestions.filter({ !defaultSuggestions.contains($0) })
        
        let pickedInex: Int
        
        // Suggestions should stay on the typed word if:
        if lastWord.contains(where: \.isNumber) || lastWord == allSuggestions.first || allSuggestions.count == 0 || (!FinaleKeyboard.isExperimentalAutocorrectOn && userDictionary.contains(lastWord.lowercased())) {
            pickedInex = 0
        } else {
            pickedInex = 1
        }
        
        allSuggestions.removeAll(where: { $0 == lastWord } )
        
        guard let newStorage = suggestionsManager.addSuggestions(suggestions: [lastWord] + allSuggestions, pickedIndex: pickedInex) else { return }
        
        ReplaceLastWord(withWord: newStorage.pickedSuggestion)
        SetSuggestionLabels(suggestions: newStorage, animated: false)
    }
    
    func getStandardSpellcheckSuggestions (for word: String) -> [String] {
        let spellChecker = UITextChecker()
        
        let misspelledRange = spellChecker.rangeOfMisspelledWord(in: word.lowercased(), range: NSMakeRange(0, word.count), startingAt: 0, wrap: true, language: FinaleKeyboard.currentLocale.languageCode)
        var suggestions = spellChecker.guesses(forWordRange: NSRange(location: 0, length: word.count), in: word, language: FinaleKeyboard.currentLocale.languageCode) ?? []
        
        if misspelledRange.location == NSNotFound { suggestions.insert(word, at: 0) }
        return suggestions.map { SpellCheck.matchCase(fromWord: word, toWord: $0) }
    }
    
    func getDefaultSuggestions (for word: String) -> [String] {
        guard FinaleKeyboard.isAutoCorrectGrammarOn, let suggestions = defaultDictionary[word.lowercased()] else { return [] }
        
        return suggestions.map { SpellCheck.matchCase(fromWord: word, toWord: $0) }
    }
    
    func ReplaceLastWord (withWord: String) {
        if getLastChar() == " " { self.textDocumentProxy.deleteBackward() }
        
        while !isAtWordStart() {
            self.textDocumentProxy.deleteBackward()
        }
        
        self.textDocumentProxy.insertText("\(withWord) ")
    }
    
    func CycleSuggestionsForLastWord (_ direction: SuggestionCycleDirection) {
        var dis = 0
        while let context = self.textDocumentProxy.documentContextBeforeInput, !context.isEmpty, let lastChar = getLastChar()?.unicodeScalars.first, !CharacterSet.whitespacesAndNewlines.contains(lastChar) {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            dis += 1
        }
        
        if let suggestionStorage = suggestionsManager.getCurrentSuggestions() {
            if let newSuggestion = direction == .next ? suggestionStorage.pickNextSuggestion() : suggestionStorage.pickPrevSuggestion() {
                ReplaceLastWord(withWord: newSuggestion)
                SetSuggestionLabels(suggestions: suggestionStorage, animated: true)
                
                if suggestionStorage.pickedSuggestionIndex == 0 {
                    RecordNewWord(suggestionStorage.pickedSuggestion)
                }
            } else if direction == .previous { // If SuggestionStorage returned no prevSuggestion, it means we reached the end (index 0) and should try to learn this word.
                ToggleUserDictionary(forWord: suggestionStorage.pickedSuggestion)
            }
        }
        
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: dis)
    }
    
    enum SuggestionCycleDirection {
        case next, previous
    }
}

// MARK: Suggestions UI
extension FinaleKeyboard {
    
    func ClearSuggestionLabels () {
        return SetSuggestionLabels(texts: nil, selectedIndex: nil, animated: false)
    }
    
    func SetSuggestionLabels(punctuationIndex: Int, animated: Bool = false) {
        return SetSuggestionLabels(texts: punctuationManager.punctuations, selectedIndex: punctuationIndex, animated: animated)
    }
    
    func SetSuggestionLabels(suggestions: SuggestionsManager.SuggestionsStorage?, animated: Bool = false) {
        return SetSuggestionLabels(texts: suggestions?.list, selectedIndex: suggestions?.pickedSuggestionIndex, animated: animated)
    }

    func SetSuggestionLabels (texts: [String]?, selectedIndex: Int?, animated: Bool) {
        for i in 0..<suggestionLabels.count {
            suggestionLabels[i].text = texts == nil ? "" : texts!.indices.contains(i) ? texts![i] : ""
            suggestionLabels[i].textColor = i == selectedIndex ? .label : .gray
        }
        
        self.view.layoutIfNeeded()
        
        if let selectedIndex = selectedIndex, suggestionLabels.indices.contains(selectedIndex) {
            let deltaX = self.suggestionLabels[selectedIndex].frame.origin.x + self.suggestionLabels[selectedIndex].frame.width*0.5 - self.view.frame.width*0.5
            suggestionLabelCenterXConstraint.constant -= deltaX
        } else {
            suggestionLabelCenterXConstraint.constant = 0
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    func FadeSuggestions () {
        for label in self.suggestionLabels {
            if label.textColor.cgColor.alpha <= 0 { continue }
            
            UIView.transition(with: label, duration: 0.20, options: .transitionCrossDissolve) {
                label.textColor = label.textColor.withAlphaComponent(label.textColor.cgColor.alpha-0.25)
            }
        }
    }
    
    func RestoreSuggestionsLabels () {
        if let oneBeforeLastChar = getOneBeforeLastChar(), punctuationManager.isPunctuation(char: oneBeforeLastChar) {
            SetSuggestionLabels(texts: punctuations, selectedIndex: punctuations.firstIndex(of: String(oneBeforeLastChar)), animated: false)
        } else {
            SetSuggestionLabels(suggestions: suggestionsManager.getCurrentSuggestions(), animated: false)
        }
    }
}
