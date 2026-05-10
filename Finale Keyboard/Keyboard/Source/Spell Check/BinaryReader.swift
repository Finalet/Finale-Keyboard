//
//  BinaryReader.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/9/26.
//

import Foundation

final class BinaryReader {
    static let shared = BinaryReader()

    func loadKeyboardMatrix(for locale: Locale, bundle: Bundle = .main) -> SpellCheck.KeyboardMatrix.KeyboardMatrixSnapshot? {
        guard let file = loadFile(for: locale, bundle: bundle),
              let payload = file.sectionPayload(for: .keyboardMatrix) else {
            return nil
        }

        return KeyboardMatrixSectionReader.decode(payload: payload)
    }

    func loadDictionary(for locale: Locale, bundle: Bundle = .main) -> SpellCheck.LoadedDictionary? {
        guard let file = loadFile(for: locale, bundle: bundle),
              let payload = file.sectionPayload(for: .dictionary) else {
            return nil
        }

        return DictionarySectionReader.decode(payload: payload)
    }

    func loadCandidateBitsets(for locale: Locale, bundle: Bundle = .main) -> SpellCheck.CandidateBitsetFilter.Snapshot? {
        guard let file = loadFile(for: locale, bundle: bundle),
              let payload = file.sectionPayload(for: .candidateBitsets) else {
            return nil
        }

        return CandidateBitsetSectionReader.decode(payload: payload)
    }

    private func loadFile(for locale: Locale, bundle: Bundle) -> FSCBinaryFile? {
        guard let url = bundle.url(forResource: locale.languageCode, withExtension: FSCBinaryFormat.fileExtension),
              let data = try? Data(contentsOf: url),
              let file = FSCBinaryFile(data: data),
              file.localeIdentifier == locale.languageCode else {
            return nil
        }

        return file
    }
}

private enum FSCBinaryFormat {
    static let fileExtension = "fscdict"
    static let magic = Data([0x46, 0x53, 0x43, 0x44])
    static let version: UInt16 = 1

    enum SectionID: UInt32 {
        case keyboardMatrix = 1
        case dictionary = 2
        case candidateBitsets = 3
    }
}

private struct FSCBinaryFile {
    let localeIdentifier: String

    private let data: Data
    private let sections: [FSCBinaryFormat.SectionID: SectionRange]

    init?(data: Data) {
        var reader = BinaryPayloadReader(data: data)

        guard reader.readData(count: FSCBinaryFormat.magic.count) == FSCBinaryFormat.magic,
              reader.readUInt16() == FSCBinaryFormat.version,
              let localeIdentifier = reader.readString(),
              let sectionCount = reader.readUInt16() else {
            return nil
        }

        var parsedSections: [(id: FSCBinaryFormat.SectionID, range: SectionRange)] = []
        parsedSections.reserveCapacity(Int(sectionCount))

        for _ in 0..<sectionCount {
            guard let rawSectionID = reader.readUInt32(),
                  let sectionID = FSCBinaryFormat.SectionID(rawValue: rawSectionID),
                  let offset = reader.readUInt64(),
                  let byteCount = reader.readUInt64(),
                  let range = SectionRange(offset: offset, byteCount: byteCount, dataCount: data.count) else {
                return nil
            }

            parsedSections.append((id: sectionID, range: range))
        }

        let payloadStart = reader.currentOffset
        var sections: [FSCBinaryFormat.SectionID: SectionRange] = [:]
        sections.reserveCapacity(parsedSections.count)

        for section in parsedSections {
            guard section.range.range.lowerBound >= payloadStart,
                  sections[section.id] == nil else {
                return nil
            }

            sections[section.id] = section.range
        }

        self.localeIdentifier = localeIdentifier
        self.data = data
        self.sections = sections
    }

    func sectionPayload(for id: FSCBinaryFormat.SectionID) -> Data? {
        guard let range = sections[id] else { return nil }
        return data.subdata(in: range.range)
    }
}

private struct KeyboardMatrixSectionReader {
    static func decode(payload: Data) -> SpellCheck.KeyboardMatrix.KeyboardMatrixSnapshot? {
        var reader = BinaryPayloadReader(data: payload)

        guard let indexMapCount = reader.readUInt16() else { return nil }

        var indexMap: [Character: SpellCheck.MatrixIndex] = [:]
        indexMap.reserveCapacity(Int(indexMapCount))

        for _ in 0..<indexMapCount {
            guard let characterString = reader.readString(),
                  characterString.count == 1,
                  let character = characterString.first,
                  let matrixIndex = reader.readUInt8(),
                  indexMap[character] == nil else {
                return nil
            }

            indexMap[character] = matrixIndex
        }

        guard let proximityMatrixSizeValue = reader.readUInt16(),
              let proximityScoreCountValue = reader.readUInt32(),
              let proximityScoreCount = Int(exactly: proximityScoreCountValue) else {
            return nil
        }

        let proximityMatrixSize = Int(proximityMatrixSizeValue)
        guard proximityMatrixSize > 0,
              indexMap.count == proximityMatrixSize,
              proximityScoreCount == proximityMatrixSize * proximityMatrixSize,
              Set(indexMap.values).count == indexMap.count,
              indexMap.values.allSatisfy({ Int($0) < proximityMatrixSize }) else {
            return nil
        }

        var proximityMatrix: [Float] = []
        proximityMatrix.reserveCapacity(proximityScoreCount)

        for _ in 0..<proximityScoreCount {
            guard let score = reader.readFloat32(), score.isFinite else {
                return nil
            }

            proximityMatrix.append(score)
        }

        guard reader.isAtEnd else { return nil }

        return SpellCheck.KeyboardMatrix.KeyboardMatrixSnapshot(indexMap: indexMap, proximityMatrix: proximityMatrix, proximityMatrixSize: proximityMatrixSize)
    }
}

private struct DictionarySectionReader {
    static func decode(payload: Data) -> SpellCheck.LoadedDictionary? {
        var reader = BinaryPayloadReader(data: payload)

        guard let validWordCountValue = reader.readUInt32(),
              let validWordCount = Int(exactly: validWordCountValue) else {
            return nil
        }

        var validWords = Set<String>()
        validWords.reserveCapacity(validWordCount)

        for _ in 0..<validWordCount {
            guard let word = reader.readString(),
                  !word.isEmpty,
                  validWords.insert(word).inserted else {
                return nil
            }
        }

        guard let groupCount = reader.readUInt16() else {
            return nil
        }

        var words: SpellCheck.WordDictionary = [:]
        words.reserveCapacity(Int(groupCount))

        for _ in 0..<groupCount {
            guard let lengthValue = reader.readUInt16(),
                  let candidateCountValue = reader.readUInt32(),
                  let candidateCount = Int(exactly: candidateCountValue) else {
                return nil
            }

            let length = Int(lengthValue)
            guard length > 0, words[length] == nil else {
                return nil
            }

            var candidates: SpellCheck.WordFrequencyDictionary = []
            candidates.reserveCapacity(candidateCount)

            for _ in 0..<candidateCount {
                guard let word = reader.readString(),
                      !word.isEmpty,
                      let frequency = reader.readFloat32(),
                      frequency.isFinite,
                      let matrixIndexCountValue = reader.readUInt16() else {
                    return nil
                }

                let matrixIndexCount = Int(matrixIndexCountValue)
                guard matrixIndexCount == length else {
                    return nil
                }

                var matrixIndexes: [SpellCheck.MatrixIndex] = []
                matrixIndexes.reserveCapacity(matrixIndexCount)

                for _ in 0..<matrixIndexCount {
                    guard let matrixIndex = reader.readUInt8(),
                          matrixIndex != SpellCheck.unknownMatrixIndex else {
                        return nil
                    }

                    matrixIndexes.append(matrixIndex)
                }

                candidates.append((word: word, frequency: frequency, matrixIndexes: matrixIndexes))
            }

            words[length] = candidates
        }

        guard reader.isAtEnd else { return nil }

        return (words: words, validWords: validWords)
    }
}

private struct CandidateBitsetSectionReader {
    static func decode(payload: Data) -> SpellCheck.CandidateBitsetFilter.Snapshot? {
        var reader = BinaryPayloadReader(data: payload)

        guard let groupCount = reader.readUInt16() else {
            return nil
        }

        var lengthIndexes: [Int: SpellCheck.CandidateBitsetFilter.LengthIndexSnapshot] = [:]
        lengthIndexes.reserveCapacity(Int(groupCount))

        for _ in 0..<groupCount {
            guard let lengthValue = reader.readUInt16(),
                  let candidateCountValue = reader.readUInt32(),
                  let candidateCount = Int(exactly: candidateCountValue),
                  let wordBitsValue = reader.readUInt16(),
                  let allWordsCountValue = reader.readUInt32(),
                  let allWordsCount = Int(exactly: allWordsCountValue) else {
                return nil
            }

            let length = Int(lengthValue)
            let wordBits = Int(wordBitsValue)

            var allWords: [UInt64] = []
            allWords.reserveCapacity(allWordsCount)
            for _ in 0..<allWordsCount {
                guard let word = reader.readUInt64() else { return nil }
                allWords.append(word)
            }

            guard let nearBitsetCountValue = reader.readUInt32(),
                  let nearBitsetCount = Int(exactly: nearBitsetCountValue) else {
                return nil
            }

            var nearBitsets: [UInt64] = []
            nearBitsets.reserveCapacity(nearBitsetCount)
            for _ in 0..<nearBitsetCount {
                guard let word = reader.readUInt64() else { return nil }
                nearBitsets.append(word)
            }

            lengthIndexes[length] = SpellCheck.CandidateBitsetFilter.LengthIndexSnapshot(length: length, candidateCount: candidateCount, wordBits: wordBits, allWords: allWords, nearBitsets: nearBitsets)
        }

        guard reader.isAtEnd else {
            return nil
        }

        return SpellCheck.CandidateBitsetFilter.Snapshot(lengthIndexes: lengthIndexes)
    }
}

private struct SectionRange {
    let range: Range<Int>

    init?(offset: UInt64, byteCount: UInt64, dataCount: Int) {
        guard let start = Int(exactly: offset),
              let length = Int(exactly: byteCount),
              length >= 0,
              start >= 0,
              start <= dataCount,
              length <= dataCount - start else {
            return nil
        }

        self.range = start..<(start + length)
    }
}

private struct BinaryPayloadReader {
    private let data: Data
    private var offset = 0

    var currentOffset: Int {
        offset
    }

    var isAtEnd: Bool {
        offset == data.count
    }

    init(data: Data) {
        self.data = data
    }

    mutating func readUInt8() -> UInt8? {
        guard let value = readData(count: 1)?.first else { return nil }
        return value
    }

    mutating func readUInt16() -> UInt16? {
        readInteger()
    }

    mutating func readUInt32() -> UInt32? {
        readInteger()
    }

    mutating func readUInt64() -> UInt64? {
        readInteger()
    }

    mutating func readFloat32() -> Float? {
        guard let bitPattern: UInt32 = readUInt32() else { return nil }
        return Float(bitPattern: bitPattern)
    }

    mutating func readData(count: Int) -> Data? {
        guard count >= 0,
              offset <= data.count,
              count <= data.count - offset else {
            return nil
        }

        let range = offset..<(offset + count)
        offset += count
        return data.subdata(in: range)
    }

    mutating func readLengthPrefixedData() -> Data? {
        guard let byteCount = readUInt32(),
              let count = Int(exactly: byteCount) else {
            return nil
        }

        return readData(count: count)
    }

    mutating func readString() -> String? {
        guard let stringData = readLengthPrefixedData() else {
            return nil
        }

        return String(data: stringData, encoding: .utf8)
    }

    private mutating func readInteger<T: FixedWidthInteger>() -> T? {
        let byteCount = MemoryLayout<T>.size
        guard let bytes = readData(count: byteCount) else { return nil }

        var value: T = 0
        withUnsafeMutableBytes(of: &value) { destination in
            bytes.withUnsafeBytes { source in
                destination.copyBytes(from: source)
            }
        }

        return T(littleEndian: value)
    }
}
