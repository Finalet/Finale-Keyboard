//
//  PunctuationManager.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/14/26.
//

class PunctuationManager {

    var punctuations: [String] = []

    private var lastPlacedPunctuationIndex: Int? = nil

    init () {
        self.punctuations = FinaleKeyboard.userDefaults?.value(forKey: "FINALE_DEV_APP_punctuationArray") as? [String] ?? Defaults.punctuation
    }

    func recordInsertedPunctuation (index: Int) {
        lastPlacedPunctuationIndex = index
    }

    func clearLastInsertedPunctuation () {
        lastPlacedPunctuationIndex = nil
    }

    var lastPlacedPunctuation: Punctuation? {
        guard let lastPlacedPunctuationIndex, let character = getPunctuation(forIndex: lastPlacedPunctuationIndex) else { return nil }
        return Punctuation(index: lastPlacedPunctuationIndex, character: character)
    }
    
    func getNextPunctuation (current: String) -> Punctuation? {
        return getPunctuationWithOffset(current: current, offset: 1)
    }
    
    func getPreviousPunctuation (current: String) -> Punctuation? {
        return getPunctuationWithOffset(current: current, offset: -1)
    }
    
    func getPunctuationWithOffset (current: String, offset: Int) -> Punctuation? {
        guard let current = getIndex(forPunctuation: current) else { return nil }

        let nextIndex = current + offset

        guard let character = getPunctuation(forIndex: nextIndex) else { return nil }
        
        return Punctuation(index: nextIndex, character: character)
    }

    func getPunctuation (forIndex: Int) -> String? {
        guard punctuations.indices.contains(forIndex) else { return nil }
        return punctuations[forIndex]
    }
    
    func getIndex (forPunctuation: String) -> Int? {
        return punctuations.firstIndex(of: forPunctuation)
    }

    func isPunctuation(char: String) -> Bool {
        return punctuations.contains(char)
    }
    
    func isPunctuation(char: Character) -> Bool {
        return isPunctuation(char: String(char))
    }
    
    func isPunctuation(char: String, ignoreCharacters: [String]) -> Bool {
        if ignoreCharacters.contains(char) { return false }
        else { return isPunctuation(char: char) }
    }
    
    struct Punctuation {
        var index: Int
        var character: String
    }
}
