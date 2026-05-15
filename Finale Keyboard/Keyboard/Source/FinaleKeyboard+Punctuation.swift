//
//  FinaleKeyboard+Punctuation.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/14/26.
//

extension FinaleKeyboard {
    
    func InsertPunctuation (index: Int = 0) {
        guard let punctuation = punctuationManager.getPunctuation(forIndex: index) else { return }
                
        self.textDocumentProxy.deleteBackward()
        self.textDocumentProxy.insertText("\(punctuation) ")

        SetSuggestionLabels(punctuationIndex: index, animated: false)
        
        punctuationManager.recordInsertedPunctuation(index: index)
    }
    
    func CyclePunctuations (current: String, _ direction: SuggestionCycleDirection) {
        guard let punctuation = direction == .next ? punctuationManager.getNextPunctuation(current: current) : punctuationManager.getPreviousPunctuation(current: current) else { return }

        var dis = 0
        while let lastChar = getLastChar(), lastChar != " " {
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)
            dis += 1
        }

        for _ in 0...1 {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.insertText("\(punctuation.character) ")
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: dis)

        SetSuggestionLabels(punctuationIndex: punctuation.index, animated: true)

        punctuationManager.recordInsertedPunctuation(index: punctuation.index)
        
        CheckAutoCapitalization()
    }
    
}
