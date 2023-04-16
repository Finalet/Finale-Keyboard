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
        case .Backspace: FinaleKeyboard.instance.ShowShortcutPreviews()
        default: return
        }
    }
    
    func LongPressEndedAction () {
        switch self {
        case .Backspace: FinaleKeyboard.instance.HideShortcutPreviews()
        default: return
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

struct DictionaryItem: Decodable {
    let input: String
    let suggestions: [String]
}
