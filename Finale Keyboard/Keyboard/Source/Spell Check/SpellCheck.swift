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
        let cleanedWord = cleanWord(word)
        if cleanedWord.isEmpty { return [] }
        
        let candidates = getCandidates(forWord: cleanedWord)
        
        var scored: [ScoredCandidate] = []
        
        let lock = NSLock()
        DispatchQueue.concurrentPerform(iterations: candidates.count) { i in
            let scores: [ScoredCandidate] = candidates[i].map { (word: $0.key, score: scoreCandidate(forWord: cleanedWord, candidate: ($0.key, $0.value))) }
            
            lock.lock()
            scored.append(contentsOf: scores)
            lock.unlock()
        }
        
        return scored.sorted(by: { $0.score > $1.score }).map { $0.word }.prefix(5).map { String($0) }
    }

    func scoreCandidate(forWord: String, candidate: CorrectionCandidate) -> Float {
        var score: Float = 0.0
        
        // Increase score based on how aligned its to the candidate
        let alignmentScore = self.getAlignmentScore(word: forWord, candidate: candidate.word) * Weights.alignment
        score += alignmentScore
        
        // Increase the score based on the word's frequency in the language.
        let frequencyScore = candidate.frequency * Weights.frequency
        score += frequencyScore
        
        // Penalize candidates that are very unlikely
        if candidate.frequency < 0.0002 {
            score -= Scores.lowFrequencyPenalty * Weights.lowFrequencyPenalty
        }
        
        return score
    }
    
    func getProximityScore(char1: Character, char2: Character) -> Float {
        guard let index1 = getMatrixIndex(char1), let index2 = getMatrixIndex(char2) else {
            return Scores.wrongCharacter
        }
        
        let distance = proximityMatrix[index1][index2]
        
        if distance == 0 { return Scores.matchBonus }
        if distance < 0.13 { return Scores.matchBonus * 0.5 }
        if distance < 0.2 { return Scores.matchBonus * 0.25 }
        return Scores.wrongCharacter
    }
    
    private func getAlignmentScore(word: String, candidate: String) -> Float {
        let wordCharacters = Array(word)
        let candidateCharacters = Array(candidate)

        // Reject obviosuly wrong candidates early.
        // If the first two characters don't match, its the wrong candidate.
        if wordCharacters.count >= 2, candidateCharacters.count >= 2 {
            let firstScore = getProximityScore(char1: wordCharacters[0], char2: candidateCharacters[0])
            let secondScore = getProximityScore(char1: wordCharacters[1], char2: candidateCharacters[1])

            if firstScore == Scores.wrongCharacter, secondScore == Scores.wrongCharacter {
                return -Float.infinity
            }
        }
        
        var scores: [[Float]] = Array(repeating: Array(repeating: Float(0.0), count: candidateCharacters.count + 1), count: wordCharacters.count + 1)

        // Fill the first column by repeatedly skipping letters from the input word.
        // This handles cases where the typed word has extra characters.
        for i in 1...wordCharacters.count {
            scores[i][0] = scores[i - 1][0] - Scores.characterSkipPenalty
        }

        // Fill the first row by repeatedly skipping letters from the candidate.
        // This handles cases where the typed word is missing characters.
        for j in 1...candidateCharacters.count {
            scores[0][j] = scores[0][j - 1] - Scores.characterSkipPenalty
        }

        // Fill the rest of the grid by choosing the best alignment move at each point.
        for i in 1...wordCharacters.count {
            for j in 1...candidateCharacters.count {
                let wordCharacter = wordCharacters[i - 1]
                let candidateCharacter = candidateCharacters[j - 1]

                // Align the two current letters.
                let substitutionScore = scores[i - 1][j - 1] + getProximityScore(char1: wordCharacter, char2: candidateCharacter)

                // Skip one typed letter.
                let skippedWordScore = scores[i - 1][j] - Scores.characterSkipPenalty

                // Skip one candidate letter.
                let skippedCandidateScore = scores[i][j - 1] - Scores.characterSkipPenalty

                var transpositionScore = -Float.infinity
                if i > 1, j > 1, wordCharacters[i - 2] == candidateCharacters[j - 1], wordCharacters[i - 1] == candidateCharacters[j - 2] {
                    transpositionScore = scores[i - 2][j - 2] + Scores.matchBonus * 2 - Scores.transpositionPenalty
                }

                scores[i][j] = max(substitutionScore, skippedWordScore, skippedCandidateScore, transpositionScore)
            }
        }
        
        let rawScore = scores[wordCharacters.count][candidateCharacters.count]
        let normalizedScore = rawScore / max(Float(word.count) * Scores.matchBonus, 1)
        
        return normalizedScore
    }

    private func getCandidates(forWord: String) -> [WordFrequencyDictionary] {
        return [self.dictionary[forWord.count - 1], self.dictionary[forWord.count], self.dictionary[forWord.count + 1]].compactMap { $0 }
    }
    
    private func cleanWord(_ word: String) -> String {
        return word.lowercased().filter { $0.isLetter }
    }

    private static func loadDictionary(forLocale: Locale) -> WordDictionary {
        let jsonFileName: String
        switch forLocale {
        case .en_US: jsonFileName = "english"
        default: return [:]
        }
        
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
    typealias WordDictionary = [Int: WordFrequencyDictionary]
    typealias WordFrequencyDictionary = [String: Float]
    typealias CorrectionCandidate = (word: String, frequency: Float)
    typealias ScoredCandidate = (word: String, score: Float)
    
    struct CharacterProximity {
        let character: Character
        let proximityScore: Float
    }

    enum Weights {
        static let frequency: Float = 0.11
        static let lowFrequencyPenalty: Float = 1
        static let alignment: Float = 1
    }
    
    enum Scores {
        static let wrongCharacter: Float = -1
        static let matchBonus: Float = 1.0
        static let characterSkipPenalty: Float = 0.75
        static let transpositionPenalty: Float = 0.5
        static let lowFrequencyPenalty: Float = 0.25
    }
}


// Tests
extension SpellCheck {
    func RunTest() {
        let roundTimeTo = 100.0
        
        let testSubjects: [(misspelled: String, correct: String)] = [
            ("hrllo", "hello"),
            ("grkkp", "hello"),
            ("jrkkp", "hello"),
            ("proscute", "prosecute"),
            ("agter", "after"),
            ("afyer", "after"),
            ("improvig", "improving"),
            ("bexause", "because"),
            ("allpcations", "allocations"),
            ("surgave", "surface"),
            ("praxticing", "practicing"),
            ("rithm", "rhythm"),
            ("adjist", "adjust"),
            ("ti", "to"),
            ("nit", "not"),
            ("recieve", "receive"),
            ("adress", "address"),
            ("wich", "which"),
            ("becuase", "because"),
            ("freind", "friend"),
            ("goverment", "government"),
            ("enviroment", "environment"),
            ("langauge", "language"),
            ("acheive", "achieve"),
            ("acommodate", "accommodate"),
            ("watre", "water"),
            ("tabel", "table"),
            ("famliy", "family"),
            ("littel", "little"),
            ("succesful", "successful"),
            ("begining", "beginning"),
            ("thier", "their"),
            ("realy", "really"),
            ("adresss", "address"),
            ("enviornment", "environment"),
            ("wierdo", "weirdo"),
            ("algorihtm", "algorithm"),
            ("mesage", "message"),
            ("messgae", "message"),
            ("nuber", "number"),
            ("qestion", "question"),
            ("quikc", "quick"),
            ("anser", "answer"),
            ("chekc", "check"),
            ("retrun", "return"),
            ("pritn", "print"),
            ("fucntion", "function"),
            ("strign", "string"),
            ("modle", "model"),
            ("compuer", "computer")
        ].sorted(by: { $0.correct.count < $1.correct.count })

        
//        let testSubjects: [(misspelled: String, correct: String)] = [
//            ("ti", "to")
//        ].sorted(by: { $0.correct.count < $1.correct.count })
        
        var results: [(misspelled: String, correct: String, ACresult: [String], timeTook: TimeInterval)] = []
        
        for subject in testSubjects {
            let startTime = Date()
            
            let corrections = correct(word: subject.misspelled)
            
            results.append((subject.misspelled, subject.correct, corrections, Date().timeIntervalSince(startTime)))
        }

        let totalCorrect = results.filter { $0.ACresult.first == $0.correct }.count
        let totalTime = results.reduce(0) { $0 + $1.timeTook }
        let averageTime = totalTime / Double(results.count)
        
        print ("📝 Autocorrect results 📝")
        print ("")
        print ("- Correct: \((totalCorrect * 100) / results.count)% (\(totalCorrect)/\(results.count))")
        print ("- Average time: \(round(averageTime * roundTimeTo * 1000) / roundTimeTo) ms")
        print ("- Total time: \(round(totalTime * roundTimeTo * 1000) / roundTimeTo) ms")
        print ("")
        
        print ("❌ Wrong")
        for result in results.filter({ $0.ACresult.first != $0.correct }) {
            print("\t- \(result.misspelled) -> \(result.ACresult.first ?? "-") (correct: \(result.correct)) | Best candidates: \(result.ACresult) | Took: \(round(result.timeTook * roundTimeTo * 1000) / roundTimeTo) ms")
        }
        
        print ("✅ Correct")
        for result in results.filter({ $0.ACresult.first == $0.correct }) {
            print("\t- \(result.misspelled) -> \(result.ACresult.first!) | Best candidates: \(result.ACresult) | Took: \(round(result.timeTook * roundTimeTo * 1000) / roundTimeTo) ms")
        }
    }
}

// Speed testing
//
// UITextChecker(): avg. 0.8ms, total: 40ms
// Baseline, no improvements: avg. 168ms, total 8.6s
// Score each length candidates in parallel: avg. 88ms, total 4.5s
// Reject bad candidates early: avg. 42ms, total 2.1s

