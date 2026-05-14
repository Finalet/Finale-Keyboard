//
//  SuggestionsManager.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/14/26.
//

class SuggestionsManager {

    var storage: [SuggestionsStorage] = []

    private let maxSuggestionHistory: Int = 5
    private let maxSuggestions: Int = 7

    func addSuggestions (suggestions: [String], pickedIndex: Int) -> SuggestionsStorage? {
        if storage.count >= maxSuggestionHistory { storage.removeFirst() }

        guard let newStorage = SuggestionsStorage(list: suggestions, pickedIndex: pickedIndex) else { return nil }
        
        storage.append(newStorage)
        return newStorage
    }

    func getSuggestions(forWord: String) -> SuggestionsStorage? {
        return storage.first {
            $0.list.indices.contains($0.pickedSuggestionIndex) && $0.list[$0.pickedSuggestionIndex] == forWord
        }
    }

    func getCurrentSuggestions() -> SuggestionsStorage? {
        guard let lastWord = FinaleKeyboard.instance.getLastWord() else { return nil }
        return self.getSuggestions(forWord: lastWord)
    }

    func deleteSuggestions(forWord: String) {
        storage.removeAll {
            $0.list.indices.contains($0.pickedSuggestionIndex) && $0.list[$0.pickedSuggestionIndex] == forWord
        }
    }

    class SuggestionsStorage {
        var list: [String]
        var pickedSuggestionIndex: Int

        init? (list: [String], pickedIndex: Int) {
            guard !list.isEmpty, list.indices.contains(pickedIndex) else { return nil }
            
            self.list = list
            self.pickedSuggestionIndex = pickedIndex
        }

        var pickedSuggestion: String {
            return list[pickedSuggestionIndex]
        }

        func pickNextSuggestion() -> String? {
            return pickSuggestionWithOffset(1)
        }

        func pickPrevSuggestion() -> String? {
            return pickSuggestionWithOffset(-1)
        }
        
        private func pickSuggestionWithOffset(_ offset: Int) -> String? {
            let nextIndex = pickedSuggestionIndex + offset
            guard list.indices.contains(nextIndex)  else { return nil }
            
            pickedSuggestionIndex = nextIndex
            return pickedSuggestion
        }
    }
}
