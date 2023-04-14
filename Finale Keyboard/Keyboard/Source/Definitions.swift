//
//  Definitions.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/12/23.
//

import Foundation
import UIKit


enum Function {
    case Shift
    case SymbolsShift
    case ExtraSymbolsShift
    case Backspace
    case Caps
    case Back
    
    var icon: UIImage? {
        switch self {
        case .Shift: return UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(weight: .black))
        case .SymbolsShift: return UIImage(systemName: "character.textbox", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        case .ExtraSymbolsShift: return UIImage(systemName: "123.rectangle", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        case .Caps: return UIImage(systemName: "arrow.up.to.line", withConfiguration: UIImage.SymbolConfiguration(weight: .black))
        case .Backspace: return UIImage(systemName: "delete.left.fill")
        case .Back: return UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        }
    }
    
    func TapAction () {
        switch self {
        case .Shift: FinaleKeyboard.instance.ShiftAction()
        case .SymbolsShift: FinaleKeyboard.instance.ToggleExtraSymbolsView()
        case .ExtraSymbolsShift: FinaleKeyboard.instance.ToggleExtraSymbolsView()
        case .Caps: FinaleKeyboard.instance.ShiftAction()
        case .Backspace: FinaleKeyboard.instance.BackspaceAction()
        case .Back: FinaleKeyboard.instance.BackAction()
        }
    }
    
    func LongPressAction () {
        switch self {
        case .Shift: FinaleKeyboard.instance.ToggleAutoCorrect()
        case .Caps: FinaleKeyboard.instance.ToggleAutoCorrect()
        case .Backspace: FinaleKeyboard.instance.BackspaceAction()
        default: return
        }
    }
    
    var isLongPressRepeatable: Bool {
        switch self {
        case .Backspace: return true
        default: return false
        }
    }
    
    func SwipeRight () {
        if self == .Shift || self == .SymbolsShift || self == .ExtraSymbolsShift || self == .Caps {
            FinaleKeyboard.instance.ToggleSymbolsView()
        }
    }
    func SwipeLeft () {
        if self == .Backspace {
            FinaleKeyboard.currentViewType == .SearchEmoji ? FinaleKeyboard.instance.BackAction() : FinaleKeyboard.instance.OpenEmoji()
        }
    }
    func SwipeUp () {
        if self == .Shift || self == .Caps {
            FinaleKeyboard.instance.ToggleLocale()
        } else if self == .Backspace {
            FinaleKeyboard.currentViewType == .SearchEmoji ? FinaleKeyboard.instance.BackAction() : FinaleKeyboard.instance.ReturnAction()
        }
    }
    
    func SwipeDown () {}
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
    
    var topRow: [Character] {
        switch self {
        case .en_US: return ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        case .ru_RU: return ["й", "ц", "у" , "к", "е", "н", "г", "ш", "щ", "з", "х"]
        }
    }
    var middleRow: [Character] {
        switch self {
        case .en_US: return ["a", "s", "d", "f",  "g", "h", "j", "k", "l"]
        case .ru_RU: return ["ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э"]
        }
    }
    var bottomRow: [Character] {
        switch self {
        case .en_US: return ["z", "x", "c", "v", "b", "n", "m"]
        case .ru_RU: return ["ч", "с", "м", "и", "т", "ь", "б", "ю"]
        }
    }
}
struct DictionaryItem: Decodable {
    let input: String
    let suggestions: [String]
}
