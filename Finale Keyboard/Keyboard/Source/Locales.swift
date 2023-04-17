//
//  Locales.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/3/22.
//

import Foundation

enum Locale: Int {
    case en_US
    case ru_RU
    
    var topRow: [String] {
        switch self {
        case .en_US: return ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        case .ru_RU: return ["й", "ц", "у" , "к", "е", "н", "г", "ш", "щ", "з", "х"]
        }
    }
    var middleRow: [String] {
        switch self {
        case .en_US: return ["a", "s", "d", "f",  "g", "h", "j", "k", "l"]
        case .ru_RU: return ["ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э"]
        }
    }
    var bottomRow: [String] {
        switch self {
        case .en_US: return ["z", "x", "c", "v", "b", "n", "m"]
        case .ru_RU: return ["я", "ч", "с", "м", "и", "т", "ь", "б", "ю"]
        }
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
