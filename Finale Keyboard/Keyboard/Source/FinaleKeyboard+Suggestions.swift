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
        if lastWord.contains(where: \.isNumber) || lastWord == allSuggestions.first || (!FinaleKeyboard.isExperimentalAutocorrectOn && userDictionary.contains(lastWord.lowercased())) {
            pickedInex = 0
        } else {
            pickedInex = 1
        }
        
        allSuggestions.removeAll(where: { $0 == lastWord } )
        
        guard let newStorage = SuggestionManager.addSuggestions(suggestions: [lastWord] + allSuggestions, pickedIndex: pickedInex) else { return }
        
        ReplaceLastWord(withWord: newStorage.pickedSuggestion)
        SetSuggestionLabels(suggestions: newStorage, animated: false)
    }
    
    func getStandardSpellcheckSuggestions (for word: String) -> [String] {
        let spellChecker = UITextChecker()
        
        let misspelledRange = spellChecker.rangeOfMisspelledWord(in: word.lowercased(), range: NSMakeRange(0, word.count), startingAt: 0, wrap: true, language: FinaleKeyboard.currentLocale.languageCode)
        var suggestions = spellChecker.guesses(forWordRange: NSRange(location: 0, length: word.count), in: word, language: FinaleKeyboard.currentLocale.languageCode) ?? []
        
        if misspelledRange.location == NSNotFound { suggestions.insert(word, at: 0) }
        return suggestions.map { matchCase(fromWord: word, toWord: $0) }
    }
    
    func getDefaultSuggestions (for word: String) -> [String] {
        guard FinaleKeyboard.isAutoCorrectGrammarOn, let suggestions = defaultDictionary[word.lowercased()] else { return [] }
        
        return suggestions.map { matchCase(fromWord: word, toWord: $0) }
    }
    
    func matchCase (fromWord: String, toWord: String) -> String {
        // If the correct spelling is uppercased, do not change it (i.e. USSR should always be USSR).
        if toWord == toWord.uppercased() {
            return toWord
        }
        
        if fromWord == fromWord.firstCapitalized {
            return toWord.firstCapitalized
        } else if fromWord == fromWord.uppercased() {
            return toWord.uppercased()
        }
        return toWord
    }
    
    func ReplaceLastWord (withWord: String) {
        if getLastChar() == " " { self.textDocumentProxy.deleteBackward() }
        
        while !isAtWordStart() {
            self.textDocumentProxy.deleteBackward()
        }
        
        self.textDocumentProxy.insertText("\(withWord) ")
    }
    
    func CycleSuggestionsForLastWord (dir: Int) {
        guard (dir == -1 || dir == 1) else { return }
        
        var dis = 0
        while let context = self.textDocumentProxy.documentContextBeforeInput, !context.isEmpty, let lastChar = getLastChar()?.unicodeScalars.first, !CharacterSet.whitespacesAndNewlines.contains(lastChar) {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            dis += 1
        }
        
        if let suggestionStorage = SuggestionManager.getCurrentSuggestions(), let newSuggestion = dir == 1 ? suggestionStorage.pickNextSuggestion() : suggestionStorage.pickPrevSuggestion() {
            ReplaceLastWord(withWord: newSuggestion)
            SetSuggestionLabels(suggestions: suggestionStorage, animated: true)
        }
        
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: dis)
    }
}

// MARK: Suggestions UI
extension FinaleKeyboard {
    
    func ClearSuggestionLabels () {
        return SetSuggestionLabels(texts: nil, selectedIndex: nil, animated: false)
    }
    
    func SetSuggestionLabels(suggestions: SuggestionsManager.SuggestionsStorage?, animated: Bool = false) {
        return SetSuggestionLabels(texts: suggestions?.list, selectedIndex: suggestions?.pickedSuggestionIndex, animated: animated)
    }

    func SetSuggestionLabels (texts: [String]?, selectedIndex: Int?, animated: Bool) {
        for i in 0..<suggestionLabels.count {
            suggestionLabels[i].text = texts == nil ? "" : texts!.indices.contains(i) ? texts![i] : ""
            suggestionLabels[i].textColor = i == selectedIndex ? .label : .gray
        }
        
        if let selectedIndex = selectedIndex, suggestionLabels.indices.contains(selectedIndex) {
            let deltaX = self.suggestionLabels[selectedIndex].frame.origin.x + self.suggestionLabels[selectedIndex].frame.width*0.5 - UIScreen.main.bounds.width*0.5
            centerXConstraint.constant -= deltaX
        } else {
            centerXConstraint.constant = 0
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
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
    
    func ResetSuggestionsLabels () {
        suggestionLabels.forEach {
            $0.text = ""
            $0.textColor = .gray
        }
        centerXConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    
    func RedrawSuggestionsLabels () {
        if let oneBeforeLastChar = getOneBeforeLastChar(), isPunctuation(char: oneBeforeLastChar) {
            pickedPunctuationIndex = punctuationArray.firstIndex(of: String(oneBeforeLastChar))!
            UpdateSuggestionsLabelsPunctuation()
            AnimateSuggestionLabels(index: pickedPunctuationIndex, instant: true)
        } else {
            SetSuggestionLabels(suggestions: SuggestionManager.getCurrentSuggestions(), animated: false)
        }
    }
}
