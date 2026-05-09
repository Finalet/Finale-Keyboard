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
    let proximityMatrix: [Float]
    let proximityMatrixSize: Int
    let matrixIndexMap: [MatrixIndex]
    private let candidateFilter: CandidateBitsetFilter

    init (locale: Locale) {
        self.locale = locale
        let matrixIndexMap = SpellCheck.getMatrixIndexMap(locale: locale)
        self.matrixIndexMap = matrixIndexMap
        let dictionary = SpellCheck.loadDictionary(forLocale: locale, indexMap: matrixIndexMap)
        self.dictionary = dictionary
        let proximityMatrix = SpellCheck.getProximityMatrix(locale: locale, indexMap: matrixIndexMap)
        self.proximityMatrix = proximityMatrix.scores
        self.proximityMatrixSize = proximityMatrix.size
        self.candidateFilter = CandidateBitsetFilter(dictionary: dictionary, proximityMatrix: proximityMatrix.scores, proximityMatrixSize: proximityMatrix.size)
    }

    func correct(word: String, nSuggestions: Int = 5) -> [String] {
        guard nSuggestions > 0 else { return [] }

        let cleanedWord = cleanWord(word)
        if cleanedWord.isEmpty { return [] }
        
        let wordMatrixIndexes = getMatrixIndexes(forWord: cleanedWord)
        let candidates = candidateFilter.candidates(for: wordMatrixIndexes)
        
        var topCandidates: [ScoredCandidate] = []
        topCandidates.reserveCapacity(nSuggestions)
        
        for candidate in candidates {
            let score = scoreCandidate(forWord: cleanedWord, candidate: candidate)
            if score.isFinite {
                insertScoredCandidate((word: candidate.word, score: score), into: &topCandidates, maxCount: nSuggestions)
            }
        }
        
        return topCandidates.map { $0.word }
    }

    private func insertScoredCandidate(_ candidate: ScoredCandidate, into topCandidates: inout [ScoredCandidate], maxCount: Int) {
        guard maxCount > 0 else { return }

        var insertIndex: Int
        if topCandidates.count < maxCount {
            topCandidates.append(candidate)
            insertIndex = topCandidates.count - 1
        } else {
            guard let last = topCandidates.last, candidate.score > last.score else { return }
            topCandidates[topCandidates.count - 1] = candidate
            insertIndex = topCandidates.count - 1
        }

        while insertIndex > 0, topCandidates[insertIndex].score > topCandidates[insertIndex - 1].score {
            topCandidates.swapAt(insertIndex, insertIndex - 1)
            insertIndex -= 1
        }
    }

    func scoreCandidate(forWord: String, candidate: CorrectionCandidate) -> Float {
        var score: Float = 0.0
        
        // Increase score based on how aligned its to the candidate
        let alignmentScore = self.getAlignmentScore(word: forWord, candidate: candidate.word, minimumUsefulScore: 0.5) * Weights.alignment
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
        
        return getProximityScore(index1: index1, index2: index2)
    }

    func getProximityScore(index1: MatrixIndex, index2: MatrixIndex) -> Float {
        return SpellCheck.getProximityScore(index1: index1, index2: index2, proximityMatrix: proximityMatrix, proximityMatrixSize: proximityMatrixSize)
    }

    private static func getProximityScore(index1: MatrixIndex, index2: MatrixIndex, proximityMatrix: [Float], proximityMatrixSize: Int) -> Float {
        guard index1 != SpellCheck.unknownMatrixIndex, index2 != SpellCheck.unknownMatrixIndex else {
            return Scores.wrongCharacter
        }

        return proximityMatrix[Int(index1) * proximityMatrixSize + Int(index2)]
    }

    private static func getProximityScore(forDistance distance: Float) -> Float {
        if distance == 0 { return Scores.matchBonus }
        if distance < 0.13 { return Scores.matchBonus * 0.5 }
        if distance < 0.2 { return Scores.matchBonus * 0.25 }
        return Scores.wrongCharacter
    }
    
    private func getAlignmentScore(word: String, candidate: String, minimumUsefulScore: Float? = nil) -> Float {
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
            
            if let minimumUsefulScore {
                let bestScoreInRow = scores[i].max() ?? -Float.infinity
                let remainingCharacters = wordCharacters.count - i

                let bestPossibleRawScore = bestScoreInRow + Float(remainingCharacters) * Scores.matchBonus

                let bestPossibleNormalizedScore = bestPossibleRawScore / max(Float(word.count) * Scores.matchBonus, 1)

                if bestPossibleNormalizedScore < minimumUsefulScore {
                    return -Float.infinity
                }
            }
        }
        
        let rawScore = scores[wordCharacters.count][candidateCharacters.count]
        let normalizedScore = rawScore / max(Float(word.count) * Scores.matchBonus, 1)
        
        return normalizedScore
    }

    private func cleanWord(_ word: String) -> String {
        return word.lowercased().filter { $0.isLetter }
    }

    private static func loadDictionary(forLocale: Locale, indexMap: [MatrixIndex]) -> WordDictionary {
        let jsonFileName: String
        switch forLocale {
        case .en_US: jsonFileName = "english"
        default: return [:]
        }
        
        guard let file = Bundle.main.url(forResource: jsonFileName, withExtension: "json"), let data = try? Data(contentsOf: file), let entries = try? JSONDecoder().decode(RawWordDictionary.self, from: data) else {
            return [:]
        }
        return entries.mapValues { words in
            words.map { entry in
                return (word: entry.key, frequency: entry.value, matrixIndexes: SpellCheck.getMatrixIndexes(forWord: entry.key, indexMap: indexMap))
            }
        }
    } 

    private func getMatrixIndex(_ char: Character) -> MatrixIndex? {
        guard let scalar = char.unicodeScalars.first, scalar.value <= UInt8.max else { return nil }
        let index = matrixIndexMap[Int(scalar.value)]
        return index == SpellCheck.unknownMatrixIndex ? nil : index
    }

    private func getMatrixIndexes(forWord word: String) -> [MatrixIndex] {
        return SpellCheck.getMatrixIndexes(forWord: word, indexMap: matrixIndexMap)
    }

    private static func getMatrixIndexes(forWord word: String, indexMap: [MatrixIndex]) -> [MatrixIndex] {
        return word.unicodeScalars.map {
            guard $0.value <= UInt8.max else { return SpellCheck.unknownMatrixIndex }
            return indexMap[Int($0.value)]
        }
    }

    private static func getMatrixIndexMap(locale: Locale) -> [MatrixIndex] {
        let alphabet = locale.topRow + locale.middleRow + locale.bottomRow
        var map = Array(repeating: SpellCheck.unknownMatrixIndex, count: 256)
        for (index, key) in alphabet.enumerated() {
            guard let scalar = key.unicodeScalars.first, scalar.value <= UInt8.max else { continue }
            map[Int(scalar.value)] = MatrixIndex(index)
        }
        return map 
    }

    // A N x N matrix, where N is the number of character keys in the keyboard, that contains the proximity score between each pair of keys.
    private static func getProximityMatrix(locale: Locale, indexMap: [MatrixIndex]) -> (scores: [Float], size: Int) {
        let rows = [locale.topRow, locale.middleRow, locale.bottomRow]
        let alphabetCount = rows.reduce(0) { $0 + $1.count }

        // First, calculate coordinates of each key button. X: range from 0 to 1, Y: range from 0 to ~0.22.
        // Y is scaled down from 0 to 1 towards 0 to ~0.22, to reflect the aspect ratio of the keyboard. This way X and Y represent the same real physical distance between the keys.

        var buttonCoordinates: [(UInt8, (x: Float, y: Float))] = []
        buttonCoordinates.reserveCapacity(rows.reduce(0) { $0 + $1.count }) // Reserve capacity to improve performance.
        
        let scaleY = Float(rows.count) * Float(FinaleKeyboard.rowHeight) * 0.5 / Float(UIScreen.main.bounds.width)

        for (rowIndex, row) in rows.enumerated() {
            for (colIndex, key) in row.enumerated() {
                // Third row has two extra buttons that are not character keys (shift and backspace). Our distances need to account for that.
                let isBottomRow = rowIndex == 2                
                let x = Float(colIndex + (isBottomRow ? 1 : 0)) / Float(row.count - 1 + (isBottomRow ? 2 : 0))
                let y = scaleY * Float(rowIndex) / Float(rows.count - 1)
                
                guard let scalar = key.unicodeScalars.first, scalar.value <= UInt8.max else { continue }
                buttonCoordinates.append((UInt8(scalar.value), (x: x, y: y)))
            }
        }

        var matrix = Array(repeating: Scores.wrongCharacter, count: alphabetCount * alphabetCount)

        for i in buttonCoordinates.indices {
            let (code1, coord1) = buttonCoordinates[i]
            let i1 = indexMap[Int(code1)]
            guard i1 != SpellCheck.unknownMatrixIndex else { continue }
            matrix[Int(i1) * alphabetCount + Int(i1)] = Scores.matchBonus

            for j in (i + 1)..<buttonCoordinates.count {
                let (code2, coord2) = buttonCoordinates[j]
                let i2 = indexMap[Int(code2)]
                guard i2 != SpellCheck.unknownMatrixIndex else { continue }

                let dx = coord1.x - coord2.x
                let dy = coord1.y - coord2.y
                let distance = sqrt(dx * dx + dy * dy)
                let proximityScore = getProximityScore(forDistance: distance)

                matrix[Int(i1) * alphabetCount + Int(i2)] = proximityScore
                matrix[Int(i2) * alphabetCount + Int(i1)] = proximityScore
            }
        }
        
        return (matrix, alphabetCount)
    }
}

// Types
extension SpellCheck {
    typealias MatrixIndex = UInt8
    typealias WordDictionary = [Int: WordFrequencyDictionary]
    typealias RawWordDictionary = [Int: [String: Float]]
    typealias WordFrequencyDictionary = [CorrectionCandidate]
    typealias CorrectionCandidate = (word: String, frequency: Float, matrixIndexes: [MatrixIndex])
    typealias ScoredCandidate = (word: String, score: Float)

    static let unknownMatrixIndex = MatrixIndex.max

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

    enum Search {
        static let maxStructuralEdits = 1
        static let maxWrongSubstitutions = 1
    }
}

// Candidate Filtering
extension SpellCheck {
    private struct CandidateBitsetFilter {
        private struct LengthIndex {
            let candidates: [CorrectionCandidate]
            let wordBits: Int
            let allWords: [UInt64]
            let nearBitsets: [UInt64]

            init(candidates: [CorrectionCandidate], proximityMatrix: [Float], proximityMatrixSize: Int) {
                self.candidates = candidates
                self.wordBits = max(1, (candidates.count + 63) / 64)

                var allWords = Array(repeating: UInt64.max, count: wordBits)
                let remainder = candidates.count & 63
                if remainder != 0 {
                    allWords[wordBits - 1] = (UInt64(1) << UInt64(remainder)) - 1
                }
                self.allWords = allWords

                let wordLength = candidates.first?.matrixIndexes.count ?? 0
                var nearBitsets = Array(repeating: UInt64(0), count: wordLength * proximityMatrixSize * wordBits)

                for candidateIndex in candidates.indices {
                    let bitWord = candidateIndex >> 6
                    let bit = UInt64(1) << UInt64(candidateIndex & 63)

                    for position in candidates[candidateIndex].matrixIndexes.indices {
                        let candidateMatrixIndex = candidates[candidateIndex].matrixIndexes[position]
                        guard candidateMatrixIndex != SpellCheck.unknownMatrixIndex else { continue }

                        for typedIndex in 0..<proximityMatrixSize {
                            let proximityScore = proximityMatrix[typedIndex * proximityMatrixSize + Int(candidateMatrixIndex)]
                            guard proximityScore != Scores.wrongCharacter else { continue }
                            nearBitsets[(position * proximityMatrixSize + typedIndex) * wordBits + bitWord] |= bit
                        }
                    }
                }

                self.nearBitsets = nearBitsets
            }

            func bitsetOffset(position: Int, typedIndex: MatrixIndex, proximityMatrixSize: Int) -> Int? {
                guard typedIndex != SpellCheck.unknownMatrixIndex else { return nil }
                let offset = (position * proximityMatrixSize + Int(typedIndex)) * wordBits
                guard nearBitsets.indices.contains(offset) else { return nil }
                return offset
            }
        }

        private let lengthIndexes: [Int: LengthIndex]
        private let proximityMatrixSize: Int

        init(dictionary: WordDictionary, proximityMatrix: [Float], proximityMatrixSize: Int) {
            var lengthIndexes: [Int: LengthIndex] = [:]
            lengthIndexes.reserveCapacity(dictionary.count)

            for (length, candidates) in dictionary {
                let sortedCandidates = candidates.sorted { $0.word < $1.word }
                lengthIndexes[length] = LengthIndex(candidates: sortedCandidates, proximityMatrix: proximityMatrix, proximityMatrixSize: proximityMatrixSize)
            }

            self.lengthIndexes = lengthIndexes
            self.proximityMatrixSize = proximityMatrixSize
        }

        func candidates(for wordMatrixIndexes: [MatrixIndex]) -> [CorrectionCandidate] {
            let wordLength = wordMatrixIndexes.count
            var candidates: [CorrectionCandidate] = []

            func fill(_ target: inout [UInt64], with source: [UInt64]) {
                for index in target.indices {
                    target[index] = source[index]
                }
            }

            func clear(_ target: inout [UInt64]) {
                for index in target.indices {
                    target[index] = 0
                }
            }

            func union(_ source: [UInt64], into target: inout [UInt64]) {
                for index in target.indices {
                    target[index] |= source[index]
                }
            }

            func intersect(position: Int, typedPosition: Int, in lengthIndex: LengthIndex, into target: inout [UInt64]) -> Bool {
                guard let bitsetOffset = lengthIndex.bitsetOffset(position: position, typedIndex: wordMatrixIndexes[typedPosition], proximityMatrixSize: proximityMatrixSize) else {
                    clear(&target)
                    return false
                }

                var hasAnyMatch = false
                for index in target.indices {
                    let value = target[index] & lengthIndex.nearBitsets[bitsetOffset + index]
                    target[index] = value
                    hasAnyMatch = hasAnyMatch || value != 0
                }
                return hasAnyMatch
            }

            func addSameLengthMatches(from lengthIndex: LengthIndex, resultBits: inout [UInt64], workBits: inout [UInt64]) {
                guard wordLength > 0 else { return }

                fill(&workBits, with: lengthIndex.allWords)
                for position in 0..<wordLength {
                    guard intersect(position: position, typedPosition: position, in: lengthIndex, into: &workBits) else { break }
                }
                union(workBits, into: &resultBits)

                if Search.maxWrongSubstitutions > 0 {
                    for wildcardPosition in 0..<wordLength {
                        fill(&workBits, with: lengthIndex.allWords)
                        for position in 0..<wordLength where position != wildcardPosition {
                            guard intersect(position: position, typedPosition: position, in: lengthIndex, into: &workBits) else { break }
                        }
                        union(workBits, into: &resultBits)
                    }
                }

                guard Search.maxStructuralEdits > 0, wordLength > 1 else { return }

                for transpositionPosition in 0..<(wordLength - 1) {
                    fill(&workBits, with: lengthIndex.allWords)
                    for position in 0..<wordLength {
                        let typedPosition: Int
                        if position == transpositionPosition {
                            typedPosition = position + 1
                        } else if position == transpositionPosition + 1 {
                            typedPosition = position - 1
                        } else {
                            typedPosition = position
                        }

                        guard intersect(position: position, typedPosition: typedPosition, in: lengthIndex, into: &workBits) else { break }
                    }
                    union(workBits, into: &resultBits)
                }
            }

            func addShorterMatches(from lengthIndex: LengthIndex, resultBits: inout [UInt64], workBits: inout [UInt64]) {
                guard Search.maxStructuralEdits > 0, wordLength > 1 else { return }
                let candidateLength = wordLength - 1

                for skippedWordPosition in 0..<wordLength {
                    fill(&workBits, with: lengthIndex.allWords)
                    for candidatePosition in 0..<candidateLength {
                        let typedPosition = candidatePosition < skippedWordPosition ? candidatePosition : candidatePosition + 1
                        guard intersect(position: candidatePosition, typedPosition: typedPosition, in: lengthIndex, into: &workBits) else { break }
                    }
                    union(workBits, into: &resultBits)
                }
            }

            func addLongerMatches(from lengthIndex: LengthIndex, resultBits: inout [UInt64], workBits: inout [UInt64]) {
                guard Search.maxStructuralEdits > 0 else { return }
                let candidateLength = wordLength + 1

                for skippedCandidatePosition in 0..<candidateLength {
                    fill(&workBits, with: lengthIndex.allWords)
                    for candidatePosition in 0..<candidateLength where candidatePosition != skippedCandidatePosition {
                        let typedPosition = candidatePosition < skippedCandidatePosition ? candidatePosition : candidatePosition - 1
                        guard intersect(position: candidatePosition, typedPosition: typedPosition, in: lengthIndex, into: &workBits) else { break }
                    }
                    union(workBits, into: &resultBits)
                }
            }

            func appendMatches(from lengthIndex: LengthIndex, resultBits: [UInt64]) {
                for wordBitIndex in resultBits.indices {
                    var bits = resultBits[wordBitIndex]

                    while bits != 0 {
                        let bit = bits & (0 &- bits)
                        let candidateIndex = wordBitIndex * 64 + bit.trailingZeroBitCount
                        bits &= bits - 1

                        guard lengthIndex.candidates.indices.contains(candidateIndex) else { continue }
                        candidates.append(lengthIndex.candidates[candidateIndex])
                    }
                }
            }

            func visitLength(_ candidateLength: Int, collector: (LengthIndex, inout [UInt64], inout [UInt64]) -> Void) {
                guard let lengthIndex = lengthIndexes[candidateLength] else { return }

                var resultBits = Array(repeating: UInt64(0), count: lengthIndex.wordBits)
                var workBits = Array(repeating: UInt64(0), count: lengthIndex.wordBits)
                collector(lengthIndex, &resultBits, &workBits)
                appendMatches(from: lengthIndex, resultBits: resultBits)
            }

            visitLength(wordLength, collector: addSameLengthMatches)
            visitLength(wordLength - 1, collector: addShorterMatches)
            visitLength(wordLength + 1, collector: addLongerMatches)

            return candidates
        }
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
// Reject candidates who can't reach minimum useful score: avg. 28ms, total 1.3s
// Filter candidates with a bitset: avg. 1.8ms, total: 90ms.
