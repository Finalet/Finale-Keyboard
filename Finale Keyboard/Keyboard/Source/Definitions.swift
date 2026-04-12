//
//  Definitions.swift
//  Keyboard
//
//  Created by Grant Oganyan on 4/12/23.
//

import Foundation
import UIKit


enum Function {
    // Default functions
    case Shift
    case SymbolsShift
    case ExtraSymbolsShift
    case Backspace
    case Caps
    case Back
    
    // Spacebar row functions
    case SymbolsToggle
    case SymbolsToggleBack
    case EmojiToggle
    case Return
    
    var icon: UIImage? {
        switch self {
            case .Shift: return UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(weight: .black))
            case .SymbolsShift: return UIImage(systemName: "number", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            case .ExtraSymbolsShift: return UIImage(systemName: "numbers", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            case .Caps: return UIImage(systemName: "arrow.up.to.line", withConfiguration: UIImage.SymbolConfiguration(weight: .black))
            case .Backspace: return UIImage(systemName: "delete.left.fill")
            case .Back: return UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
            case .SymbolsToggle: return UIImage(systemName: "numbers", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            case .SymbolsToggleBack: return UIImage(systemName: "characters.uppercase", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            case .EmojiToggle: return UIImage(systemName: "face.smiling", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
            case .Return: return UIImage(systemName: "return", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
        }
    }
    
    func OnTapBegin () {
        switch self {
            case .SymbolsToggle: FinaleKeyboard.instance.ToggleSymbolsView()
            case .SymbolsToggleBack: FinaleKeyboard.instance.ToggleSymbolsView()
            default: return
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
            case .EmojiToggle: FinaleKeyboard.instance.OpenEmoji()
            case .Return: FinaleKeyboard.instance.ReturnAction()
            default: return
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
            case .SymbolsToggle: FinaleKeyboard.instance.ToggleSymbolsView()
            case .SymbolsToggleBack: FinaleKeyboard.instance.ToggleSymbolsView()
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

enum KeyboardRow {
    case Top
    case Middle
    case Bottom
}
