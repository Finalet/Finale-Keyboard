//
//  Definitions.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/12/23.
//

import Foundation
import UIKit

enum ActionType {
    case Character
    case Function
}

enum FunctionType {
    case Shift
    case SymbolsShift
    case ExtraSymbolsShift
    case Backspace
    case Caps
    case Back
    case none
    
    var icon: UIImage? {
        switch self {
        case .Shift: return UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(weight: .black))
        case .SymbolsShift: return UIImage(systemName: "character.textbox", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        case .ExtraSymbolsShift: return UIImage(systemName: "123.rectangle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        case .Caps: return UIImage(systemName: "arrow.up.to.line", withConfiguration: UIImage.SymbolConfiguration(weight: .black))
        case .Backspace: return UIImage(systemName: "delete.left.fill")
        case .Back: return UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        case .none: return nil
        }
    }
}

enum ViewType {
    case Characters
    case Symbols
    case ExtraSymbols
    case Emoji
    case SearchEmoji
}

enum Locale: Int {
    case en_US
    case ru_RU
}
struct DictionaryItem: Decodable {
    let input: String
    let suggestions: [String]
}
