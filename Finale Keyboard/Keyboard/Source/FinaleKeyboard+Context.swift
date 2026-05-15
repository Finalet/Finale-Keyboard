//
//  FinaleKeyboard+Context.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/13/26.
//

import Foundation
import UIKit

extension FinaleKeyboard {
    
    func getLastChar() -> Character? {
        guard let context = self.textDocumentProxy.documentContextBeforeInput, let last = context.last else { return nil }
        return last
    }
    
    func getOneBeforeLastChar() -> Character? {
        guard let context = self.textDocumentProxy.documentContextBeforeInput, context.count >= 2 else { return nil }
        return context[context.index(context.endIndex, offsetBy: -2)]
    }
    
    func getStringBeforeCursor(length: Int) -> String? {
        guard let context = self.textDocumentProxy.documentContextBeforeInput, !context.isEmpty else { return nil }
        return String(context[context.index(context.endIndex, offsetBy: -min(length, context.count))..<context.endIndex])
    }
    
    func isAtWordStart() -> Bool {
        if !self.textDocumentProxy.hasText { return true }
        let breakingCharacters = CharacterSet.whitespacesAndNewlines.union(["\"", "(", "[", "{", "<", "#", "@"])
        if let lastUnicodeChar = self.textDocumentProxy.documentContextBeforeInput?.last?.unicodeScalars.first {
            return breakingCharacters.contains(lastUnicodeChar)
        }
        return true
    }
    
    func getLastWord() -> String? {
        guard let context = self.textDocumentProxy.documentContextBeforeInput, context.count > 0 else { return nil }
        
        let chunks = context.split(separator: " ")
        
        guard let last = chunks.last else { return nil }
        
        let breakingCharacters = CharacterSet.whitespacesAndNewlines.union(["\"", "(", "[", "{", "<", "#", "@"])
        let lastWord = String(last).trimmingCharacters(in: breakingCharacters)
        
        return lastWord.isEmpty ? nil : lastWord
    }
    
}
