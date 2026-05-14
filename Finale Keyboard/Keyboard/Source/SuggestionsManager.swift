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

    func addSuggestions (suggestions: [String], pickedIndex: Int) -> SuggestionsStorage {
        if storage.count >= maxSuggestionHistory { storage.removeFirst() }

        let newStorage = SuggestionsStorage(list: suggestions, pickedIndex: pickedIndex)
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

        init(list: [String], pickedIndex: Int) {
            self.list = list
            self.pickedSuggestionIndex = pickedIndex
        }

        var pickedSuggestion: String {
            return list[pickedSuggestionIndex]
        }

        func pickNextSuggestion() -> String? {
            let nextIndex = pickedSuggestionIndex + 1
            if list.indices.contains(nextIndex) {
                pickedSuggestionIndex = nextIndex
                return pickedSuggestion
            }
            return nil
        }

        func pickPrevSuggestion() -> String? {
            let prevIndex = pickedSuggestionIndex - 1
            if list.indices.contains(prevIndex) {
                pickedSuggestionIndex = prevIndex
                return pickedSuggestion
            }
            return nil
        }
    }
}
