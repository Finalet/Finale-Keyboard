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
    
    func GenerateAutocorrections() {
        guard let lastWord = getLastWord() else { return }
        
        if (suggestionsArrays[nextSuggestionArray].suggestions.count != 0) {
            suggestionsArrays[nextSuggestionArray].suggestions.removeAll()
            suggestionsArrays[nextSuggestionArray].lastPickedSuggestionIndex = 1
            suggestionsArrays[nextSuggestionArray].positionIndex = String().startIndex
        }
        suggestionsArrays[nextSuggestionArray].suggestions.append(lastWord)
        suggestionsArrays[nextSuggestionArray].positionIndex = self.textDocumentProxy.documentContextBeforeInput!.endIndex
        suggestionsArrays[nextSuggestionArray].lastPickedSuggestionIndex = 0
        
        AppendSuggestionFromDictionary(dict: defaultDictionary, lastWord: lastWord)
        
        var suggestions: [String] = !FinaleKeyboard.isExperimentalAutocorrectOn ? getStandardSpellcheckSuggestions(for: lastWord) : (spellChecker?.suggestions(forWord: lastWord)?.compactMap({ $0.word }) ?? getStandardSpellcheckSuggestions(for: lastWord))
        
        if lastWord.contains(where: \.isNumber) {
            pickedSuggestionIndex = 0
        } else if lastWord == suggestions.first {
            suggestions.removeFirst()
            pickedSuggestionIndex = 0
        } else if suggestions.contains(lastWord) && defaultDictionary[lastWord.lowercased()] == nil { // defaultDictionary[lastWord.lowercased()] == nil is a patch for old autocorrect. Once we move away from it, we should remove this.
            suggestions.removeAll(where: { $0 == lastWord })
            pickedSuggestionIndex = 1
        } else {
            pickedSuggestionIndex = 1
        }
        
        suggestionsArrays[nextSuggestionArray].suggestions.append(contentsOf: suggestions)
        while suggestionsArrays[nextSuggestionArray].suggestions.count > maxSuggestions { suggestionsArrays[nextSuggestionArray].suggestions.removeLast() }
        
        nextSuggestionArray = (nextSuggestionArray+1) % maxSuggestionHistory
        
        // This is redundant when using our new SpellCheck. However, when its not used, we still need to enforce user dictionary
        CheckUserDictionary()
    }
    
    func getStandardSpellcheckSuggestions (for word: String) -> [String] {
        let spellChecker = UITextChecker()
        
        let misspelledRange = spellChecker.rangeOfMisspelledWord(in: word.lowercased(), range: NSMakeRange(0, word.count), startingAt: 0, wrap: true, language: FinaleKeyboard.currentLocale.languageCode)
        var suggestions = spellChecker.guesses(forWordRange: NSRange(location: 0, length: word.count), in: word, language: FinaleKeyboard.currentLocale.languageCode) ?? []
        
        if misspelledRange.location == NSNotFound { suggestions.insert(word, at: 0) }
        return suggestions.map { matchCase(fromWord: word, toWord: $0) }
    }
    
    func AppendSuggestionFromDictionary (dict: Dictionary<String, [String]>, lastWord: String) {
        if !FinaleKeyboard.isAutoCorrectGrammarOn { return }
        
        if (dict[lastWord.lowercased()] != nil) {
            let suggestions = dict[lastWord.lowercased()]!.map { matchCase(fromWord: lastWord, toWord: $0) }
            suggestionsArrays[nextSuggestionArray].suggestions.append(contentsOf: suggestions)
        }
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
    
    func ReplaceWithSuggestion (ignoreSpace: Bool = false, instant: Bool = false, tryLearnNewWord: Bool = false) {
        let x = getCorrectSuggestionArrayIndex()
        if x < 0 { return }
        
        if ignoreSpace{ self.textDocumentProxy.deleteBackward() }
        
        if (suggestionsArrays[x].suggestions.count > 1) {
            while !isAtWordStart() {
                if (self.textDocumentProxy.documentContextBeforeInput == nil || self.textDocumentProxy.documentContextBeforeInput?.last == nil) { break }
                self.textDocumentProxy.deleteBackward()
            }
            
            let suggestion = suggestionsArrays[x].suggestions[pickedSuggestionIndex]
            self.textDocumentProxy.insertText(suggestion)
            
            if tryLearnNewWord { TryLearnNewWord(word: suggestion.lowercased()) }
        } else {
            pickedSuggestionIndex = 0
        }
        
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
    
    func CheckUserDictionary () {
        let x = getCorrectSuggestionArrayIndex()
        if x < 0 { return }
        
        if suggestionsArrays[x].suggestions.count >= 2 {
            if userDictionary.contains(suggestionsArrays[x].suggestions[0].lowercased()) {
                pickedSuggestionIndex = 0
            }
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
}

// MARK: Suggestions UI
extension FinaleKeyboard {
    
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
            UpdateSuggestionsLabels()
            AnimateSuggestionLabels(index: pickedSuggestionIndex, instant: true)
        }
    }
}
