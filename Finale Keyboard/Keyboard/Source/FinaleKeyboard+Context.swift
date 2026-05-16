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
    
    func getLastWord() -> String? {
        guard let context = self.textDocumentProxy.documentContextBeforeInput, context.count > 0, let last = context.split(separator: " ").last else { return nil }
        
        let breakingCharacters = CharacterSet.whitespacesAndNewlines.union(["\"", "(", "[", "{", "<", "#", "@"])
        let lastWord = String(last.drop { character in
            character.unicodeScalars.allSatisfy { breakingCharacters.contains($0) }
        })
        
        return lastWord.isEmpty ? nil : lastWord
    }
    
}
