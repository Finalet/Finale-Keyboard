//
//  SpellCheck.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/7/26.
//

import Foundation
import UIKit

class SpellCheck {
    
    let locale: Locale
    let dictionary: WordDictionary
    let proximityMatrix: [[Float]]
    let matrixIndexMap: [Character: Int]

    init (locale: Locale) {
        self.locale = locale
        self.dictionary = SpellCheck.loadDictionary(forLocale: locale)
        self.matrixIndexMap = SpellCheck.getMatrixIndexMap(locale: locale)
        self.proximityMatrix = SpellCheck.getProximityMatrix(locale: locale, indexMap: self.matrixIndexMap)
    }

    func correct(word: String) -> [String] {
        let candidates = self.dictionary[word.count]
        let scored: [CorrectionCandidate] = candidates?.compactMap { key, _ in
            return (word: key, score: scoreCandidate(forWord: word, candidate: key))
        } ?? []
        return scored.sorted(by: { $0.score > $1.score }).map { $0.word }.prefix(5).map { String($0) }
    }

    func scoreCandidate(forWord: String, candidate: String) -> Float {
        var score: Float = 0.0

        // Increase the score based on the word's frequency in the language
        score += (self.dictionary[forWord.count]?[candidate] ?? 0.0) * Weights.frequency
        
        // Increase score based on how close each character is
        for (char1, char2) in zip(forWord, candidate) {
            score += getProximityScore(char1: char1, char2: char2) * Weights.proximity
        }
        return score
    }

    func getProximityScore(char1: Character, char2: Character) -> Float {
        guard let index1 = getMatrixIndex(char1), let index2 = getMatrixIndex(char2) else {
            return Weights.wrongCharacter
        }
        
        let distance = proximityMatrix[index1][index2]
        
        if distance < 0.13 { return 1 }
        if distance < 0.2 { return 0.6 }
        return 0
    }

    private func cleanWord(_ word: String) -> String {
        return word.lowercased().filter { $0.isLetter }
    }

    private static func loadDictionary(forLocale: Locale) -> WordDictionary {
        let jsonFileName = "english"
        guard let file = Bundle.main.url(forResource: jsonFileName, withExtension: "json"), let data = try? Data(contentsOf: file), let entries = try? JSONDecoder().decode(WordDictionary.self, from: data) else {
            return [:]
        }
        return entries
    } 

    private func getMatrixIndex(_ char: Character) -> Int? {
        return matrixIndexMap[char]
    }

    private static func getMatrixIndexMap(locale: Locale) -> [Character: Int] {
        var map: [Character: Int] = [:]
        for (index, char) in locale.alphabet.enumerated() {
            map[char] = index
        }
        return map 
    }

    // A N x N matrix, where N is the number of character keys in the keyboard, that contains the distances between each pair of keys.
    private static func getProximityMatrix(locale: Locale, indexMap: [Character: Int]) -> [[Float]] {
        let alphabet = locale.alphabet 
        let rows = [locale.topRow, locale.middleRow, locale.bottomRow]

        // First, calculate coordinates of each key button. X: range from 0 to 1, Y: range from 0 to ~0.22.
        // Y is scaled down from 0 to 1 towards 0 to ~0.22, to reflect the aspect ratio of the keyboard. This way X and Y represent the same real physical distance between the keys.

        var buttonCoordinates: [(Character, (x: Float, y: Float))] = []
        buttonCoordinates.reserveCapacity(rows.reduce(0) { $0 + $1.count }) // Reserve capacity to improve performance.
        
        let scaleY = Float(rows.count) * Float(FinaleKeyboard.rowHeight) * 0.5 / Float(UIScreen.main.bounds.width)

        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, key) in row.enumerated() {
                // Third row has two extra buttons that are not character keys (shift and backspace). Our distances need to account for that.
                let isBottomRow = rowIndex == 2                
                let x = Float(colIndex + (isBottomRow ? 1 : 0)) / Float(row.count - 1 + (isBottomRow ? 2 : 0))
                let y = scaleY * Float(rowIndex) / Float(rows.count - 1)
                
                buttonCoordinates.append((Character(key), (x: x, y: y)))
            }
        }

        var matrix = Array(repeating: Array(repeating: Float(0.0), count: alphabet.count), count: alphabet.count)

        for i in buttonCoordinates.indices {
            let (char1, coord1) = buttonCoordinates[i]
            let i1 = indexMap[char1]!

            for j in (i + 1)..<buttonCoordinates.count {
                let (char2, coord2) = buttonCoordinates[j]
                let i2 = indexMap[char2]!

                let dx = coord1.x - coord2.x
                let dy = coord1.y - coord2.y
                let distance = sqrt(dx * dx + dy * dy)

                matrix[i1][i2] = distance
                matrix[i2][i1] = distance
            }
        }
        
        return matrix
    }
}

// Types
extension SpellCheck {
    typealias WordDictionary = [Int: WordFrequency]
    typealias WordFrequency = [String: Float]
    typealias CorrectionCandidate = (word: String, score: Float)
    
    struct CharacterProximity {
        let character: Character
        let proximityScore: Float
    }

    enum Weights {
        static let frequency: Float = 2
        static let proximity: Float = 1
        static let wrongCharacter: Float = -1
    }
}
