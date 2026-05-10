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

            let sections = try [
                FSCBinarySection.keyboardMatrix(for: locale)
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

    init(arguments: [String]) throws {
        guard arguments.count == 3, arguments[1] == "--output-dir", !arguments[2].isEmpty else {
            throw CompilerError.invalidArguments("Usage: BinaryCompiler --output-dir <path>")
        }

        self.outputDirectory = URL(fileURLWithPath: arguments[2], isDirectory: true)
    }
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

    static func keyboardMatrix(for locale: Locale) throws -> FSCBinarySection {
        let snapshot = SpellCheck.KeyboardMatrix.generateSnapshot(locale: locale)
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
