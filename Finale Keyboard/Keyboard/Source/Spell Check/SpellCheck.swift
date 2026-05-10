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
    
    private let keyboardMatrix: KeyboardMatrix
    private let validWords: Set<String>
    private let candidateFilter: CandidateBitsetFilter
    private let candidateScorer: CandidateScorer

    init (locale: Locale) {
        self.locale = locale
        self.keyboardMatrix = KeyboardMatrix(locale: locale)
        
        let loadedDictionary = SpellCheck.loadDictionary(forLocale: locale, keyboardMatrix: self.keyboardMatrix)
        
        self.validWords = loadedDictionary.validWords
        self.candidateFilter = CandidateBitsetFilter(dictionary: loadedDictionary.words, proximityMatrix: self.keyboardMatrix.proximityMatrix, proximityMatrixSize: self.keyboardMatrix.proximityMatrixSize)
        self.candidateScorer = CandidateScorer(proximityMatrix: self.keyboardMatrix.proximityMatrix, proximityMatrixSize: self.keyboardMatrix.proximityMatrixSize)
    }

    func suggestions(forWord: String, nSuggestions: Int = 5) -> [String] {
        guard nSuggestions > 0 else { return [] }

        let cleanedWord = cleanWordForSearch(forWord)
        if cleanedWord.isEmpty { return [] }
        
        let wordMatrixIndexes = keyboardMatrix.matrixIndexes(forWord: cleanedWord)
        let candidates = candidateFilter.candidates(for: wordMatrixIndexes)
        
        let refinedCandidateCount = max(Search.nRefinedCandidates, nSuggestions)
        var refinedCandidates: [RankedCandidate] = []
        refinedCandidates.reserveCapacity(refinedCandidateCount)

        for candidate in candidates {
            let score = candidateScorer.fastScoreCandidate(wordMatrixIndexes: wordMatrixIndexes, candidate: candidate)
            if score.isFinite {
                insertTopCandidate((candidate: candidate, score: score), into: &refinedCandidates, maxCount: refinedCandidateCount) { $0.score }
            }
        }
        
        var alignmentWorkspace = SpellCheck.CandidateScorer.AlignmentWorkspace()
        var topCandidates: [ScoredCandidate] = []
        topCandidates.reserveCapacity(nSuggestions)
        
        for refinedCandidate in refinedCandidates {
            let score = candidateScorer.scoreCandidate(wordMatrixIndexes: wordMatrixIndexes, candidate: refinedCandidate.candidate, workspace: &alignmentWorkspace)
            if score.isFinite {
                insertTopCandidate((word: refinedCandidate.candidate.word, score: score), into: &topCandidates, maxCount: nSuggestions) { $0.score }
            }
        }
        
        return topCandidates.map { $0.word }
    }

    func isMisspelled(word: String) -> Bool {
        guard !validWords.isEmpty else { return false }

        let cleanedWord = cleanWordForValidation(word)
        if cleanedWord.isEmpty { return false }

        return !validWords.contains(cleanedWord)
    }

    private func cleanWordForSearch(_ word: String) -> String {
        return SpellCheck.normalizedWordForSearch(word, locale: locale)
    }

    private func cleanWordForValidation(_ word: String) -> String {
        return SpellCheck.normalizedWordForValidation(word, locale: locale)
    }
    
    private func insertTopCandidate<T>(_ candidate: T, into topCandidates: inout [T], maxCount: Int, score: (T) -> Float) {
        guard maxCount > 0 else { return }

        var insertIndex: Int
        let candidateScore = score(candidate)
        if topCandidates.count < maxCount {
            topCandidates.append(candidate)
            insertIndex = topCandidates.count - 1
        } else {
            guard let last = topCandidates.last, candidateScore > score(last) else { return }
            topCandidates[topCandidates.count - 1] = candidate
            insertIndex = topCandidates.count - 1
        }

        while insertIndex > 0, score(topCandidates[insertIndex]) > score(topCandidates[insertIndex - 1]) {
            topCandidates.swapAt(insertIndex, insertIndex - 1)
            insertIndex -= 1
        }
    }

    private static func loadDictionary(forLocale: Locale, keyboardMatrix: KeyboardMatrix) -> LoadedDictionary {
        let jsonFileName = dictionaryFileName(for: forLocale)

        guard let file = Bundle.main.url(forResource: jsonFileName, withExtension: "json"), let data = try? Data(contentsOf: file), let entries = try? JSONDecoder().decode(RawWordDictionary.self, from: data) else {
            return (words: [:], validWords: [])
        }

        var dictionary: WordDictionary = [:]
        var validWords: Set<String> = []
        for words in entries.values {
            for entry in words {
                let validWord = normalizedWordForValidation(entry.key, locale: forLocale)
                let matchWord = normalizedWordForSearch(entry.key, locale: forLocale)
                let matrixIndexes = keyboardMatrix.matrixIndexes(forWord: matchWord)

                guard !validWord.isEmpty, !matrixIndexes.isEmpty, !matrixIndexes.contains(SpellCheck.unknownMatrixIndex) else { continue }

                validWords.insert(validWord)
                dictionary[matrixIndexes.count, default: []].append((word: entry.key, frequency: entry.value, matrixIndexes: matrixIndexes))
            }
        }
        return (words: dictionary, validWords: validWords)
    }

    private static func dictionaryFileName(for locale: Locale) -> String {
        switch locale {
        case .en_US: return "english"
        case .ru_RU: return "russian"
        case .es_ES: return "spanish"
        case .de_DE: return "german"
        }
    }

    private static func normalizedWordForSearch(_ word: String, locale: Locale) -> String {
        let foundationLocale = Foundation.Locale(identifier: locale.languageCode)
        let lowercaseWord = word.lowercased(with: foundationLocale).precomposedStringWithCanonicalMapping
        var normalizedWord = ""

        for character in lowercaseWord {
            guard character.isLetter else { continue }
            normalizedWord.append(alias(for: character, locale: locale))
        }

        return normalizedWord
    }

    private static func normalizedWordForValidation(_ word: String, locale: Locale) -> String {
        let foundationLocale = Foundation.Locale(identifier: locale.languageCode)
        let lowercaseWord = word.lowercased(with: foundationLocale).precomposedStringWithCanonicalMapping
        var normalizedWord = ""

        for index in lowercaseWord.indices {
            let character = lowercaseWord[index]
            if character.isLetter {
                normalizedWord.append(character)
            } else if isApostrophe(character), hasLetter(before: index, in: lowercaseWord), hasLetter(after: index, in: lowercaseWord) {
                normalizedWord.append("'")
            }
        }

        return normalizedWord
    }

    private static func isApostrophe(_ character: Character) -> Bool {
        return character == "'" || character == "’"
    }

    private static func hasLetter(before index: String.Index, in word: String) -> Bool {
        guard index > word.startIndex else { return false }
        return word[word.index(before: index)].isLetter
    }

    private static func hasLetter(after index: String.Index, in word: String) -> Bool {
        let nextIndex = word.index(after: index)
        guard nextIndex < word.endIndex else { return false }
        return word[nextIndex].isLetter
    }

    private static func alias(for character: Character, locale: Locale) -> Character {
        switch locale {
        case .en_US:
            return character
        case .ru_RU:
            switch character {
            case "ё": return "е"
            case "ъ": return "ь"
            default: return character
            }
        case .es_ES:
            switch character {
            case "á": return "a"
            case "é": return "e"
            case "í": return "i"
            case "ó": return "o"
            case "ú": return "u"
            case "ü": return "u"
            default: return character
            }
        case .de_DE:
            return character == "ß" ? "s" : character
        }
    }
}

// Types
extension SpellCheck {
    typealias MatrixIndex = UInt8
    typealias RawWordDictionary = [Int: [String: Float]]
    typealias LoadedDictionary = (words: WordDictionary, validWords: Set<String>)
    typealias WordDictionary = [Int: WordFrequencyDictionary]
    typealias WordFrequencyDictionary = [CorrectionCandidate]
    typealias CorrectionCandidate = (word: String, frequency: Float, matrixIndexes: [MatrixIndex])
    typealias ScoredCandidate = (word: String, score: Float)
    typealias RankedCandidate = (candidate: CorrectionCandidate, score: Float)

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
        static let minimumUsefulAlignmentScore: Float = 0.5
    }

    enum Search {
        static let nRefinedCandidates = 16
        static let maxStructuralEdits = 1
        static let maxWrongSubstitutions = 1
    }
}

// Keyboard Matrix
extension SpellCheck {
    private struct KeyboardMatrix {
        let proximityMatrix: [Float]
        let proximityMatrixSize: Int

        private let indexMap: [Character: MatrixIndex]

        init(locale: Locale) {
            self.indexMap = KeyboardMatrix.getMatrixIndexMap(locale: locale)

            let proximityMatrix = KeyboardMatrix.getProximityMatrix(locale: locale, indexMap: self.indexMap)
            
            self.proximityMatrix = proximityMatrix.scores
            self.proximityMatrixSize = proximityMatrix.size
        }

        func matrixIndexes(forWord word: String) -> [MatrixIndex] {
            return word.map {
                return indexMap[$0] ?? SpellCheck.unknownMatrixIndex
            }
        }

        private static func getMatrixIndexMap(locale: Locale) -> [Character: MatrixIndex] {
            let alphabet = locale.topRow + locale.middleRow + locale.bottomRow
            var map: [Character: MatrixIndex] = [:]
            map.reserveCapacity(alphabet.count)

            for (index, key) in alphabet.enumerated() {
                guard let character = key.first, index < Int(SpellCheck.unknownMatrixIndex) else { continue }
                map[character] = MatrixIndex(index)
            }
            return map
        }

        // A N x N matrix, where N is the number of character keys in the keyboard, that contains the proximity score between each pair of keys.
        private static func getProximityMatrix(locale: Locale, indexMap: [Character: MatrixIndex]) -> (scores: [Float], size: Int) {
            func score(forDistance distance: Float) -> Float {
                if distance == 0 { return Scores.matchBonus }
                if distance < 0.13 { return Scores.matchBonus * 0.5 }
                if distance < 0.2 { return Scores.matchBonus * 0.25 }
                return Scores.wrongCharacter
            }

            let rows = [locale.topRow, locale.middleRow, locale.bottomRow]
            let alphabetCount = rows.reduce(0) { $0 + $1.count }

            // First, calculate coordinates of each key button. X: range from 0 to 1, Y: range from 0 to ~0.22.
            // Y is scaled down from 0 to 1 towards 0 to ~0.22, to reflect the aspect ratio of the keyboard. This way X and Y represent the same real physical distance between the keys.

            var buttonCoordinates: [(Character, (x: Float, y: Float))] = []
            buttonCoordinates.reserveCapacity(rows.reduce(0) { $0 + $1.count }) // Reserve capacity to improve performance.

//            let scaleY = Float(rows.count) * Float(FinaleKeyboard.rowHeight) * 0.5 / Float(UIScreen.main.bounds.width)
            let scaleY: Float = 0.22 // I used to calculate this at run-time with the devices screen size, but I moved this into a custom binary loaded at build-time, so now its hardcoded.

            for (rowIndex, row) in rows.enumerated() {
                for (colIndex, key) in row.enumerated() {
                    // Third row has two extra buttons that are not character keys (shift and backspace). Our distances need to account for that.
                    let isBottomRow = rowIndex == 2
                    let x = Float(colIndex + (isBottomRow ? 1 : 0)) / Float(row.count - 1 + (isBottomRow ? 2 : 0))
                    let y = scaleY * Float(rowIndex) / Float(rows.count - 1)

                    guard let character = key.first else { continue }
                    buttonCoordinates.append((character, (x: x, y: y)))
                }
            }

            var matrix = Array(repeating: Scores.wrongCharacter, count: alphabetCount * alphabetCount)

            for i in buttonCoordinates.indices {
                let (character1, coord1) = buttonCoordinates[i]
                let i1 = indexMap[character1] ?? SpellCheck.unknownMatrixIndex
                guard i1 != SpellCheck.unknownMatrixIndex else { continue }
                matrix[Int(i1) * alphabetCount + Int(i1)] = Scores.matchBonus

                for j in (i + 1)..<buttonCoordinates.count {
                    let (character2, coord2) = buttonCoordinates[j]
                    let i2 = indexMap[character2] ?? SpellCheck.unknownMatrixIndex
                    guard i2 != SpellCheck.unknownMatrixIndex else { continue }

                    let dx = coord1.x - coord2.x
                    let dy = coord1.y - coord2.y
                    let distance = sqrt(dx * dx + dy * dy)
                    let proximityScore = score(forDistance: distance)

                    matrix[Int(i1) * alphabetCount + Int(i2)] = proximityScore
                    matrix[Int(i2) * alphabetCount + Int(i1)] = proximityScore
                }
            }

            return (matrix, alphabetCount)
        }
    }
}

// Candidate Scoring
extension SpellCheck {
    private struct CandidateScorer {

        struct AlignmentWorkspace {
            var previousPreviousRow: [Float] = []
            var previousRow: [Float] = []
            var currentRow: [Float] = []

            mutating func prepare(rowLength: Int) {
                Self.resize(&previousPreviousRow, to: rowLength)
                Self.resize(&previousRow, to: rowLength)
                Self.resize(&currentRow, to: rowLength)
            }

            private static func resize(_ row: inout [Float], to rowLength: Int) {
                if row.count != rowLength {
                    row = Array(repeating: 0, count: rowLength)
                }
            }
        }

        private let proximityMatrix: [Float]
        private let proximityMatrixSize: Int

        init(proximityMatrix: [Float], proximityMatrixSize: Int) {
            self.proximityMatrix = proximityMatrix
            self.proximityMatrixSize = proximityMatrixSize
        }

        func scoreCandidate(wordMatrixIndexes: [MatrixIndex], candidate: CorrectionCandidate, workspace: inout AlignmentWorkspace) -> Float {
            // Increase score based on how aligned its to the candidate
            let alignmentScore = getAlignmentScore(wordMatrixIndexes: wordMatrixIndexes, candidateMatrixIndexes: candidate.matrixIndexes, minimumUsefulScore: Scores.minimumUsefulAlignmentScore, workspace: &workspace)
            return scoreCandidate(candidate: candidate, alignmentScore: alignmentScore)
        }

        func fastScoreCandidate(wordMatrixIndexes: [MatrixIndex], candidate: CorrectionCandidate) -> Float {
            let alignmentScore = fastAlignmentScore(wordMatrixIndexes: wordMatrixIndexes, candidateMatrixIndexes: candidate.matrixIndexes)
            guard alignmentScore >= Scores.minimumUsefulAlignmentScore else { return -Float.infinity }

            return scoreCandidate(candidate: candidate, alignmentScore: alignmentScore)
        }

        private func scoreCandidate(candidate: CorrectionCandidate, alignmentScore: Float) -> Float {
            var score = alignmentScore * Weights.alignment

            // Increase the score based on the word's frequency in the language.
            let frequencyScore = candidate.frequency * Weights.frequency
            score += frequencyScore

            // Penalize candidates that are very unlikely
            if candidate.frequency < 0.0002 {
                score -= Scores.lowFrequencyPenalty * Weights.lowFrequencyPenalty
            }

            return score
        }

        private func fastAlignmentScore(wordMatrixIndexes: [MatrixIndex], candidateMatrixIndexes: [MatrixIndex]) -> Float {
            let wordLength = wordMatrixIndexes.count
            let candidateLength = candidateMatrixIndexes.count

            guard abs(wordLength - candidateLength) <= 1 else { return -Float.infinity }

            let rawScore: Float
            if wordLength == candidateLength {
                rawScore = fastSameLengthScore(wordMatrixIndexes: wordMatrixIndexes, candidateMatrixIndexes: candidateMatrixIndexes)
            } else if candidateLength == wordLength - 1 {
                rawScore = fastSkippedWordScore(wordMatrixIndexes: wordMatrixIndexes, candidateMatrixIndexes: candidateMatrixIndexes)
            } else {
                rawScore = fastSkippedCandidateScore(wordMatrixIndexes: wordMatrixIndexes, candidateMatrixIndexes: candidateMatrixIndexes)
            }

            return rawScore / max(Float(wordLength) * Scores.matchBonus, 1)
        }

        private func fastSameLengthScore(wordMatrixIndexes: [MatrixIndex], candidateMatrixIndexes: [MatrixIndex]) -> Float {
            var directScore: Float = 0

            for index in wordMatrixIndexes.indices {
                directScore += getProximityScore(index1: wordMatrixIndexes[index], index2: candidateMatrixIndexes[index])
            }

            var bestScore = directScore
            guard wordMatrixIndexes.count > 1 else { return bestScore }

            for index in 0..<(wordMatrixIndexes.count - 1) {
                guard wordMatrixIndexes[index] == candidateMatrixIndexes[index + 1], wordMatrixIndexes[index + 1] == candidateMatrixIndexes[index] else { continue }

                let directPairScore = getProximityScore(index1: wordMatrixIndexes[index], index2: candidateMatrixIndexes[index])
                    + getProximityScore(index1: wordMatrixIndexes[index + 1], index2: candidateMatrixIndexes[index + 1])
                let transpositionScore = directScore - directPairScore + Scores.matchBonus * 2 - Scores.transpositionPenalty
                bestScore = max(bestScore, transpositionScore)
            }

            return bestScore
        }

        private func fastSkippedWordScore(wordMatrixIndexes: [MatrixIndex], candidateMatrixIndexes: [MatrixIndex]) -> Float {
            var bestScore = -Float.infinity

            for skippedWordPosition in wordMatrixIndexes.indices {
                var rawScore = -Scores.characterSkipPenalty
                var candidatePosition = 0

                for wordPosition in wordMatrixIndexes.indices where wordPosition != skippedWordPosition {
                    rawScore += getProximityScore(index1: wordMatrixIndexes[wordPosition], index2: candidateMatrixIndexes[candidatePosition])
                    candidatePosition += 1
                }

                bestScore = max(bestScore, rawScore)
            }

            return bestScore
        }

        private func fastSkippedCandidateScore(wordMatrixIndexes: [MatrixIndex], candidateMatrixIndexes: [MatrixIndex]) -> Float {
            var bestScore = -Float.infinity

            for skippedCandidatePosition in candidateMatrixIndexes.indices {
                var rawScore = -Scores.characterSkipPenalty
                var wordPosition = 0

                for candidatePosition in candidateMatrixIndexes.indices where candidatePosition != skippedCandidatePosition {
                    rawScore += getProximityScore(index1: wordMatrixIndexes[wordPosition], index2: candidateMatrixIndexes[candidatePosition])
                    wordPosition += 1
                }

                bestScore = max(bestScore, rawScore)
            }

            return bestScore
        }

        private func getAlignmentScore(wordMatrixIndexes: [MatrixIndex], candidateMatrixIndexes: [MatrixIndex], minimumUsefulScore: Float? = nil, workspace: inout AlignmentWorkspace) -> Float {
            let wordLength = wordMatrixIndexes.count
            let candidateLength = candidateMatrixIndexes.count

            workspace.prepare(rowLength: candidateLength + 1)
            var hasPreviousPreviousRow = false
            workspace.previousRow[0] = 0

            // Fill the first row by repeatedly skipping letters from the candidate.
            // This handles cases where the typed word is missing characters.
            if candidateLength > 0 {
                for j in 1...candidateLength {
                    workspace.previousRow[j] = workspace.previousRow[j - 1] - Scores.characterSkipPenalty
                }
            }

            // Fill the rest of the grid by choosing the best alignment move at each point.
            if wordLength > 0 {
                for i in 1...wordLength {
                    workspace.currentRow[0] = workspace.previousRow[0] - Scores.characterSkipPenalty

                    if candidateLength > 0 {
                        for j in 1...candidateLength {
                            let wordIndex = wordMatrixIndexes[i - 1]
                            let candidateIndex = candidateMatrixIndexes[j - 1]

                            // Align the two current letters.
                            let substitutionScore = workspace.previousRow[j - 1] + getProximityScore(index1: wordIndex, index2: candidateIndex)

                            // Skip one typed letter.
                            let skippedWordScore = workspace.previousRow[j] - Scores.characterSkipPenalty

                            // Skip one candidate letter.
                            let skippedCandidateScore = workspace.currentRow[j - 1] - Scores.characterSkipPenalty

                            var transpositionScore = -Float.infinity
                            if hasPreviousPreviousRow, i > 1, j > 1, wordMatrixIndexes[i - 2] == candidateMatrixIndexes[j - 1], wordMatrixIndexes[i - 1] == candidateMatrixIndexes[j - 2] {
                                transpositionScore = workspace.previousPreviousRow[j - 2] + Scores.matchBonus * 2 - Scores.transpositionPenalty
                            }

                            workspace.currentRow[j] = max(substitutionScore, skippedWordScore, skippedCandidateScore, transpositionScore)
                        }
                    }

                    if let minimumUsefulScore {
                        let bestScoreInRow = workspace.currentRow.max() ?? -Float.infinity
                        let remainingCharacters = wordLength - i

                        let bestPossibleRawScore = bestScoreInRow + Float(remainingCharacters) * Scores.matchBonus

                        let bestPossibleNormalizedScore = bestPossibleRawScore / max(Float(wordLength) * Scores.matchBonus, 1)

                        if bestPossibleNormalizedScore < minimumUsefulScore {
                            return -Float.infinity
                        }
                    }

                    swap(&workspace.previousPreviousRow, &workspace.previousRow)
                    swap(&workspace.previousRow, &workspace.currentRow)
                    hasPreviousPreviousRow = true
                }
            }

            let rawScore = workspace.previousRow[candidateLength]
            let normalizedScore = rawScore / max(Float(wordLength) * Scores.matchBonus, 1)

            return normalizedScore
        }
        
        private func getProximityScore(index1: MatrixIndex, index2: MatrixIndex) -> Float {
            guard index1 != SpellCheck.unknownMatrixIndex, index2 != SpellCheck.unknownMatrixIndex else {
                return Scores.wrongCharacter
            }

            return proximityMatrix[Int(index1) * proximityMatrixSize + Int(index2)]
        }
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
            ("compuer", "computer"),
            ("dont", "don't"),
            ("wont", "won't"),
            ("cant", "can't")
        ].sorted(by: { $0.correct.count < $1.correct.count })

        let isMisspelledTestSubjects : [(word: String, isMisspelled: Bool)] = [
            ("dont", true),
            ("don’t", false),
            ("don't", false),
        ]
        
        var results: [(misspelled: String, correct: String, ACresult: [String], timeTook: TimeInterval)] = []
        
        for subject in testSubjects {
            let startTime = Date()
            
            let corrections = suggestions(forWord: subject.misspelled)
            
            results.append((subject.misspelled, subject.correct, corrections, Date().timeIntervalSince(startTime)))
        }

        let totalCorrect = results.filter { $0.ACresult.first == $0.correct }.count
        let totalTime = results.reduce(0) { $0 + $1.timeTook }
        let averageTime = totalTime / Double(results.count)
        let sortedTimes = results.map { $0.timeTook }.sorted()
        let p50Time = percentile(sortedTimes, percentile: 0.50)
        let p95Time = percentile(sortedTimes, percentile: 0.95)
        
        print ("📝 Autocorrect results 📝")
        print ("")
        print ("- Correct: \((totalCorrect * 100) / results.count)% (\(totalCorrect)/\(results.count))")
        print ("- Average time: \(round(averageTime * roundTimeTo * 1000) / roundTimeTo) ms")
        print ("- Total time: \(round(totalTime * roundTimeTo * 1000) / roundTimeTo) ms")
        print ("- P50 time: \(round(p50Time * roundTimeTo * 1000) / roundTimeTo) ms")
        print ("- P95 time: \(round(p95Time * roundTimeTo * 1000) / roundTimeTo) ms")
        print ("")
        
        print ("❌ Wrong")
        for result in results.filter({ $0.ACresult.first != $0.correct }) {
            print("\t- \(result.misspelled) → \(result.ACresult.first ?? "-") (correct: \(result.correct)) | Best candidates: \(result.ACresult) | Took: \(round(result.timeTook * roundTimeTo * 1000) / roundTimeTo) ms")
        }
        
        print ("✅ Correct")
        for result in results.filter({ $0.ACresult.first == $0.correct }) {
            print("\t- \(result.misspelled) → \(result.ACresult.first!) | Best candidates: \(result.ACresult) | Took: \(round(result.timeTook * roundTimeTo * 1000) / roundTimeTo) ms")
        }
        
        var isMisspelledResults: [(word: String, correct: Bool, result: Bool, timeTook: TimeInterval)] = []
        
        for subject in isMisspelledTestSubjects {
            let startTime = Date()
            
            let isMisspelledResult = isMisspelled(word: subject.word)
            
            isMisspelledResults.append((subject.word, subject.isMisspelled, isMisspelledResult, Date().timeIntervalSince(startTime)))
        }
        
        print("")
        print ("📝 Is misspelled results 📝")
        print ("")
        
        print ("❌ Wrong")
        for result in isMisspelledResults.filter({ $0.correct != $0.result }) {
            print("\t- \(result.word) → '\(result.result ? "misspelled" : "Not misspelled")' (should be '\(result.correct ? "misspelled" : "not misspelled")') | Took: \(round(result.timeTook * roundTimeTo * 1000) / roundTimeTo) ms")
        }
        if isMisspelledResults.filter({ $0.correct != $0.result }).count == 0 {
            print ("\t- None")
        }
        
        print ("✅ Correct")
        for result in isMisspelledResults.filter({ $0.correct == $0.result }) {
            print("\t- \(result.word) → '\(result.result ? "misspelled" : "Not misspelled")' | Took: \(round(result.timeTook * roundTimeTo * 1000) / roundTimeTo) ms")
        }
        if isMisspelledResults.filter({ $0.correct == $0.result }).count == 0 {
            print ("\t- None")
        }
        
    }
    
    private func percentile(_ sortedValues: [TimeInterval], percentile: Double) -> TimeInterval {
        guard !sortedValues.isEmpty else { return 0 }
        let index = min(sortedValues.count - 1, max(0, Int(Double(sortedValues.count - 1) * percentile)))
        return sortedValues[index]
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
// Faster / less RAM getAlignmentScore: avg. 1.6ms, total: 80ms.
// Pass word matrixes into getAlignmentScore: avg. 1.5ms, total: 77ms.
// Two stage scoring of candidates with fast scorrer and slow scorrer.: avg. 1.2ms, total: 60ms.
