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
        "\(Locale.ru_RU.languageCode):ч" : "Cut",
        "\(Locale.ru_RU.languageCode):с" : "Copy",
        "\(Locale.ru_RU.languageCode):м" : "Paste",
        
        "\(Locale.en_US.languageCode):x" : "Cut",
        "\(Locale.en_US.languageCode):c" : "Copy",
        "\(Locale.en_US.languageCode):v" : "Paste",
        
        "\(Locale.es_ES.languageCode):x" : "Cut",
        "\(Locale.es_ES.languageCode):c" : "Copy",
        "\(Locale.es_ES.languageCode):v" : "Paste",
        
        "\(Locale.de_DE.languageCode):s" : "ß",
        "\(Locale.de_DE.languageCode):x" : "Cut",
        "\(Locale.de_DE.languageCode):c" : "Copy",
        "\(Locale.de_DE.languageCode):v" : "Paste",
    ]
}
