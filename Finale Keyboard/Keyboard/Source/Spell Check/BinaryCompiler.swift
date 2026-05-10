//
//  BinaryCompiler.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/9/26.
//

import Foundation

@main
enum BinaryCompiler {
    static func main() throws {
        let configuration = try CompilerConfiguration(arguments: CommandLine.arguments)
        try FileManager.default.createDirectory(at: configuration.outputDirectory, withIntermediateDirectories: true, attributes: nil)

        for locale in Locale.allCases {
            guard locale == .en_US else { continue }

            let keyboardMatrixSnapshot = SpellCheck.KeyboardMatrix.generateSnapshot(locale: locale)
            let dictionaryURL = configuration.dictionaryDirectory
                .appendingPathComponent(SpellCheck.dictionaryFileName(for: locale))
                .appendingPathExtension("json")
            let dictionary = SpellCheck.loadDictionary(forLocale: locale, indexMap: keyboardMatrixSnapshot.indexMap, dictionaryURL: dictionaryURL)
            let candidateBitsets = SpellCheck.CandidateBitsetFilter.generateSnapshot(dictionary: dictionary.words, proximityMatrix: keyboardMatrixSnapshot.proximityMatrix, proximityMatrixSize: keyboardMatrixSnapshot.proximityMatrixSize)
            let sections = try [
                FSCBinarySection.keyboardMatrix(from: keyboardMatrixSnapshot),
                FSCBinarySection.dictionary(dictionary),
                FSCBinarySection.candidateBitsets(candidateBitsets)
            ]
            let data = try FSCBinaryFileWriter.compile(localeIdentifier: locale.languageCode, sections: sections)
            let outputURL = configuration.outputDirectory.appendingPathComponent(locale.languageCode).appendingPathExtension(FSCBinaryFormat.fileExtension)

            try data.write(to: outputURL, options: .atomic)
            print("Compiled \(outputURL.path)")
        }
    }
}

private struct CompilerConfiguration {
    let outputDirectory: URL
    let dictionaryDirectory: URL

    init(arguments: [String]) throws {
        var outputDirectory: URL?
        var dictionaryDirectory: URL?

        var index = 1
        while index < arguments.count {
            guard index + 1 < arguments.count else {
                throw CompilerError.invalidArguments(Self.usage)
            }

            let value = arguments[index + 1]
            switch arguments[index] {
            case "--output-dir":
                outputDirectory = URL(fileURLWithPath: value, isDirectory: true)
            case "--dictionary-dir":
                dictionaryDirectory = URL(fileURLWithPath: value, isDirectory: true)
            default:
                throw CompilerError.invalidArguments(Self.usage)
            }

            index += 2
        }

        guard let outputDirectory, let dictionaryDirectory else {
            throw CompilerError.invalidArguments(Self.usage)
        }

        self.outputDirectory = outputDirectory
        self.dictionaryDirectory = dictionaryDirectory
    }

    private static let usage = "Usage: BinaryCompiler --output-dir <path> --dictionary-dir <path>"
}

private enum CompilerError: LocalizedError {
    case invalidArguments(String)
    case stringEncodingFailed(String)
    case integerOverflow(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let message):
            return message
        case .stringEncodingFailed(let string):
            return "Could not encode string as UTF-8: \(string)"
        case .integerOverflow(let context):
            return "Integer value is too large for the .fscdict format: \(context)"
        }
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

private struct FSCBinarySection {
    let id: FSCBinaryFormat.SectionID
    let payload: Data

    static func keyboardMatrix(from snapshot: SpellCheck.KeyboardMatrix.KeyboardMatrixSnapshot) throws -> FSCBinarySection {
        var writer = BinaryPayloadWriter()

        try writer.writeUInt16(UInt16(exactly: snapshot.indexMap.count, context: "keyboard index map count"))

        for entry in snapshot.indexMap.sorted(by: { $0.value < $1.value }) {
            try writer.writeString(String(entry.key))
            writer.writeUInt8(entry.value)
        }

        try writer.writeUInt16(UInt16(exactly: snapshot.proximityMatrixSize, context: "keyboard matrix size"))
        try writer.writeUInt32(UInt32(exactly: snapshot.proximityMatrix.count, context: "keyboard proximity score count"))

        for score in snapshot.proximityMatrix {
            writer.writeFloat32(score)
        }

        return FSCBinarySection(id: .keyboardMatrix, payload: writer.data)
    }

    static func dictionary(_ dictionary: SpellCheck.LoadedDictionary) throws -> FSCBinarySection {
        var writer = BinaryPayloadWriter()

        try writer.writeUInt32(UInt32(exactly: dictionary.validWords.count, context: "valid word count"))
        for word in dictionary.validWords.sorted() {
            try writer.writeString(word)
        }

        try writer.writeUInt16(UInt16(exactly: dictionary.words.count, context: "dictionary length group count"))
        for length in dictionary.words.keys.sorted() {
            guard let candidates = dictionary.words[length] else { continue }

            try writer.writeUInt16(UInt16(exactly: length, context: "dictionary word length"))
            try writer.writeUInt32(UInt32(exactly: candidates.count, context: "dictionary candidate count"))

            for candidate in candidates.sorted(by: { $0.word < $1.word }) {
                try writer.writeString(candidate.word)
                writer.writeFloat32(candidate.frequency)
                try writer.writeUInt16(UInt16(exactly: candidate.matrixIndexes.count, context: "candidate matrix index count"))

                for matrixIndex in candidate.matrixIndexes {
                    writer.writeUInt8(matrixIndex)
                }
            }
        }

        return FSCBinarySection(id: .dictionary, payload: writer.data)
    }

    static func candidateBitsets(_ snapshot: SpellCheck.CandidateBitsetFilter.Snapshot) throws -> FSCBinarySection {
        var writer = BinaryPayloadWriter()

        try writer.writeUInt16(UInt16(exactly: snapshot.lengthIndexes.count, context: "candidate bitset length group count"))
        for length in snapshot.lengthIndexes.keys.sorted() {
            guard let lengthIndex = snapshot.lengthIndexes[length] else { continue }

            try writer.writeUInt16(UInt16(exactly: lengthIndex.length, context: "candidate bitset word length"))
            try writer.writeUInt32(UInt32(exactly: lengthIndex.candidateCount, context: "candidate bitset candidate count"))
            try writer.writeUInt16(UInt16(exactly: lengthIndex.wordBits, context: "candidate bitset word bits"))

            try writer.writeUInt32(UInt32(exactly: lengthIndex.allWords.count, context: "candidate bitset all words count"))
            for word in lengthIndex.allWords {
                writer.writeUInt64(word)
            }

            try writer.writeUInt32(UInt32(exactly: lengthIndex.nearBitsets.count, context: "candidate bitset near bitsets count"))
            for word in lengthIndex.nearBitsets {
                writer.writeUInt64(word)
            }
        }

        return FSCBinarySection(id: .candidateBitsets, payload: writer.data)
    }
}

private struct FSCBinaryFileWriter {
    private struct SectionTableEntry {
        let id: FSCBinaryFormat.SectionID
        let offset: UInt64
        let byteCount: UInt64
    }

    static func compile(localeIdentifier: String, sections: [FSCBinarySection]) throws -> Data {
        let localeData = try utf8Data(for: localeIdentifier)
        let sectionTableStartCount = FSCBinaryFormat.magic.count
            + MemoryLayout<UInt16>.size
            + MemoryLayout<UInt32>.size
            + localeData.count
            + MemoryLayout<UInt16>.size
        let sectionTableByteCount = sections.count * (MemoryLayout<UInt32>.size + MemoryLayout<UInt64>.size + MemoryLayout<UInt64>.size)
        var payloadOffset = try UInt64(exactly: sectionTableStartCount + sectionTableByteCount, context: "payload offset")

        var sectionTable: [SectionTableEntry] = []
        sectionTable.reserveCapacity(sections.count)

        for section in sections {
            let byteCount = try UInt64(exactly: section.payload.count, context: "section byte count")
            sectionTable.append(SectionTableEntry(id: section.id, offset: payloadOffset, byteCount: byteCount))
            payloadOffset = try payloadOffset.adding(byteCount, context: "payload offset")
        }

        var writer = BinaryPayloadWriter()
        writer.writeData(FSCBinaryFormat.magic)
        writer.writeUInt16(FSCBinaryFormat.version)
        try writer.writeString(localeIdentifier)
        try writer.writeUInt16(UInt16(exactly: sections.count, context: "section count"))

        for entry in sectionTable {
            writer.writeUInt32(entry.id.rawValue)
            writer.writeUInt64(entry.offset)
            writer.writeUInt64(entry.byteCount)
        }

        for section in sections {
            writer.writeData(section.payload)
        }

        return writer.data
    }

    private static func utf8Data(for string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw CompilerError.stringEncodingFailed(string)
        }

        return data
    }
}

private struct BinaryPayloadWriter {
    private(set) var data = Data()

    mutating func writeUInt8(_ value: UInt8) {
        data.append(contentsOf: [value])
    }

    mutating func writeUInt16(_ value: UInt16) {
        appendInteger(value)
    }

    mutating func writeUInt32(_ value: UInt32) {
        appendInteger(value)
    }

    mutating func writeUInt64(_ value: UInt64) {
        appendInteger(value)
    }

    mutating func writeFloat32(_ value: Float) {
        writeUInt32(value.bitPattern)
    }

    mutating func writeData(_ value: Data) {
        data.append(value)
    }

    mutating func writeLengthPrefixedData(_ value: Data) throws {
        try writeUInt32(UInt32(exactly: value.count, context: "data byte count"))
        writeData(value)
    }

    mutating func writeString(_ value: String) throws {
        guard let stringData = value.data(using: .utf8) else {
            throw CompilerError.stringEncodingFailed(value)
        }

        try writeLengthPrefixedData(stringData)
    }

    private mutating func appendInteger<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        withUnsafeBytes(of: &littleEndianValue) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}

private extension FixedWidthInteger {
    init(exactly value: Int, context: String) throws {
        guard let converted = Self(exactly: value) else {
            throw CompilerError.integerOverflow(context)
        }

        self = converted
    }

    func adding(_ value: Self, context: String) throws -> Self {
        let (result, didOverflow) = self.addingReportingOverflow(value)
        guard !didOverflow else {
            throw CompilerError.integerOverflow(context)
        }

        return result
    }
}
