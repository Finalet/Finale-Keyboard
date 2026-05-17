//
//  Locales.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/3/22.
//

import Foundation

enum Locale: Int, CaseIterable {
    case en_US
    case ru_RU
    case es_ES
    case de_DE
    
    var languageCode: String {
        switch self {
        case .en_US: return "en_US"
        case .ru_RU: return "ru_RU"
        case .es_ES: return "es_ES"
        case .de_DE: return "de_DE"
        }
    }
    
    var topRow: [String] {
        switch self {
        case .en_US: return ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        case .ru_RU: return ["й", "ц", "у" , "к", "е", "н", "г", "ш", "щ", "з", "х"]
        case .es_ES: return ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        case .de_DE: return ["q", "w", "e", "r", "t", "z", "u", "i", "o", "p", "ü"]
        }
    }
    var middleRow: [String] {
        switch self {
        case .en_US: return ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        case .ru_RU: return ["ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э"]
        case .es_ES: return ["a", "s", "d", "f", "g", "h", "j", "k", "l", "ñ"]
        case .de_DE: return ["a", "s", "d", "f", "g", "h", "j", "k", "l", "ö", "ä"]
        }
    }
    var bottomRow: [String] {
        switch self {
        case .en_US: return ["z", "x", "c", "v", "b", "n", "m"]
        case .ru_RU: return ["я", "ч", "с", "м", "и", "т", "ь", "б", "ю"]
        case .es_ES: return ["z", "x", "c", "v", "b", "n", "m"]
        case .de_DE: return ["y", "x", "c", "v", "b", "n", "m"]
        }
    }
    
    var alphabet: [Character] {
        return (topRow + middleRow + bottomRow).map { Character($0) }
    }
}

class Symbols {
    
    struct Symbols {
        static let topRow: [String] = ["1", "2","3", "4", "5", "6", "7", "8", "9", "0"]
        static let middleRow: [String] = ["-", "/" ,":", ";", "(", ")", "$", "&", "@", "\""]
        static let bottomRow: [String] = [".", ",", "?", "!", "\'"]
    }
    
    struct ExtraSymbols {
        static let topRow: [String] = ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]
        static let middleRow: [String] = ["_", "\\", "|", "~", "<", ">", "₽", "€", "£", "•"]
        static let bottomRow: [String] = [".", ",", "?", "!", "\'"]
    }
}

enum NewLocale {
    case en_US
    
    var layout: KeyboardLayout {
        switch self {
        case .en_US: return englishLayout
        }
    }
    
    var allCharacters: [Character] {
        return self.layout.languageRows.flatMap(\.keys).compactMap { key in
            guard case let .character(character, _) = key else { return nil }
            return character
        }
    }
}

let englishLayout: KeyboardLayout = .init(
    languageRows: [
        KeyboardRowNew(keys: [ .character("q"), .character("w"), .character("e"), .character("r"), .character("t"), .character("y"), .character("u"), .character("i"), .character("o"), .character("p")]),
        KeyboardRowNew(keys: [ .character("a"), .character("s"), .character("d"), .character("f"), .character("g"), .character("h"), .character("j"), .character("k"), .character("l")]),
        KeyboardRowNew(keys: [ .function(.shift), .character("z"), .character("x"), .character("c"), .character("v"), .character("b"), .character("n"), .character("m"), .function(.backspace)])
    ],
    symbolsRows: defaultSymbolsRows,
    extraSymbolsRows: defaultExtraSymbolsRows)

let defaultSymbolsRows: [KeyboardRowNew] = [
    KeyboardRowNew(keys: [ .character("q"), .character("w"), .character("e"), .character("r"), .character("t"), .character("y"), .character("u"), .character("i"), .character("o"), .character("p")]),
    KeyboardRowNew(keys: [ .character("a"), .character("s"), .character("d"), .character("f"), .character("g"), .character("h"), .character("j"), .character("k"), .character("l")]),
    KeyboardRowNew(keys: [ .function(.shift), .character("z"), .character("x"), .character("c"), .character("v"), .character("b"), .character("n"), .character("m"), .function(.backspace)])
]

let defaultExtraSymbolsRows: [KeyboardRowNew] = [
    KeyboardRowNew(keys: [ .character("q"), .character("w"), .character("e"), .character("r"), .character("t"), .character("y"), .character("u"), .character("i"), .character("o"), .character("p")]),
    KeyboardRowNew(keys: [ .character("a"), .character("s"), .character("d"), .character("f"), .character("g"), .character("h"), .character("j"), .character("k"), .character("l")]),
    KeyboardRowNew(keys: [ .function(.shift), .character("z"), .character("x"), .character("c"), .character("v"), .character("b"), .character("n"), .character("m"), .function(.backspace)])
]

struct KeyboardLayout {
    let languageRows: [KeyboardRowNew]
    let symbolsRows: [KeyboardRowNew]
    let extraSymbolsRows: [KeyboardRowNew]
}

struct KeyboardRowNew {
    let keys: [KeyboardKey]
}

enum KeyboardKey {
    case character(_ character: Character, _ secondary: [Character]? = nil)
    case function(_ function: FunctionKeyType)
}

enum FunctionKeyType {
    case shift
    case backspace
}

