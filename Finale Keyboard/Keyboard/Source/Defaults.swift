//
//  Defaults.swift
//  Keyboard
//
//  Created by Grant Oganyan on 8/22/22.
//

import Foundation

class Defaults {
    
    static let punctuation = [" ", ".", ",", "?", "!", ":", ";"]
    
    static let shortcuts: [String : String] = [
        "\(Locale.ru_RU.languageCode):е" : "ё",
        "\(Locale.ru_RU.languageCode):ь" : "ъ",
    ]
}
