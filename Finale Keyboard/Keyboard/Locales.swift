//
//  Locales.swift
//  Keyboard
//
//  Created by Grant Oganan on 2/3/22.
//

import Foundation

// MARK: en_US
let topRowActions_en = [KeyboardViewController.Action(type: .Character, title: "q"),KeyboardViewController.Action(type: .Character, title: "w"), KeyboardViewController.Action(type: .Character, title: "e"), KeyboardViewController.Action(type: .Character, title: "r"),
              KeyboardViewController.Action(type: .Character, title: "t"), KeyboardViewController.Action(type: .Character, title: "y"), KeyboardViewController.Action(type: .Character, title: "u"), KeyboardViewController.Action(type: .Character, title: "i"),
              KeyboardViewController.Action(type: .Character, title: "o"), KeyboardViewController.Action(type: .Character, title: "p")]
let middleRowActions_en = [KeyboardViewController.Action(type: .Character, title: "a"), KeyboardViewController.Action(type: .Character, title: "s"), KeyboardViewController.Action(type: .Character, title: "d"), KeyboardViewController.Action(type: .Character, title: "f"),
                 KeyboardViewController.Action(type: .Character, title: "g"), KeyboardViewController.Action(type: .Character, title: "h"), KeyboardViewController.Action(type: .Character, title: "j"), KeyboardViewController.Action(type: .Character, title: "k"),
                 KeyboardViewController.Action(type: .Character, title: "l")]
let bottomRowActions_en = [KeyboardViewController.Action(type: .Function, title: "", funcType: .Shift), KeyboardViewController.Action(type: .Character, title: "z"), KeyboardViewController.Action(type: .Character, title: "x"), KeyboardViewController.Action(type: .Character, title: "c"), KeyboardViewController.Action(type: .Character, title: "v"),
                 KeyboardViewController.Action(type: .Character, title: "b"), KeyboardViewController.Action(type: .Character, title: "n"), KeyboardViewController.Action(type: .Character, title: "m"), KeyboardViewController.Action(type: .Function, title: "", funcType: .Backspace)]

let bottomRowActionsEmojiSearch_en = [KeyboardViewController.Action(type: .Function, title: "", funcType: .Back), KeyboardViewController.Action(type: .Character, title: "z"), KeyboardViewController.Action(type: .Character, title: "x"), KeyboardViewController.Action(type: .Character, title: "c"), KeyboardViewController.Action(type: .Character, title: "v"),
                 KeyboardViewController.Action(type: .Character, title: "b"), KeyboardViewController.Action(type: .Character, title: "n"), KeyboardViewController.Action(type: .Character, title: "m"), KeyboardViewController.Action(type: .Function, title: "", funcType: .Backspace)]

// MARK: ru_RU
let topRowActions_ru = [KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"),
              KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"),
              KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??")]
let middleRowActions_ru = [KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"),
                           KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"),
                           KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??")]
let bottomRowActions_ru = [KeyboardViewController.Action(type: .Function, title: "", funcType: .Shift), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"),
                           KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"),
                           KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Function, title: "", funcType: .Backspace)]

//MARK: Symbols
let topRowSymbols = [KeyboardViewController.Action(type: .Character, title: "1", funcType: .none), KeyboardViewController.Action(type: .Character, title: "2"), KeyboardViewController.Action(type: .Character, title: "3"),
                    KeyboardViewController.Action(type: .Character, title: "4"), KeyboardViewController.Action(type: .Character, title: "5"), KeyboardViewController.Action(type: .Character, title: "6"), KeyboardViewController.Action(type: .Character, title: "7"),
                    KeyboardViewController.Action(type: .Character, title: "8"), KeyboardViewController.Action(type: .Character, title: "9"), KeyboardViewController.Action(type: .Character, title: "0")]

let middleRowSymbols = [KeyboardViewController.Action(type: .Character, title: "-", funcType: .none), KeyboardViewController.Action(type: .Character, title: "/"), KeyboardViewController.Action(type: .Character, title: ":"),
                    KeyboardViewController.Action(type: .Character, title: ";"), KeyboardViewController.Action(type: .Character, title: "("), KeyboardViewController.Action(type: .Character, title: ")"), KeyboardViewController.Action(type: .Character, title: "$"),
                    KeyboardViewController.Action(type: .Character, title: "&"), KeyboardViewController.Action(type: .Character, title: "@"), KeyboardViewController.Action(type: .Character, title: "\"")]

let bottomRowSymbols = [KeyboardViewController.Action(type: .Function, title: "", funcType: .SymbolsShift), KeyboardViewController.Action(type: .Character, title: ".", funcType: .none), KeyboardViewController.Action(type: .Character, title: ","), KeyboardViewController.Action(type: .Character, title: "?"),
                        KeyboardViewController.Action(type: .Character, title: "!"), KeyboardViewController.Action(type: .Character, title: "\'"), KeyboardViewController.Action(type: .Function, title: "", funcType: .Backspace)]

//MARK: Extra Symbols
let topRowExtraSymbols = [KeyboardViewController.Action(type: .Character, title: "[", funcType: .none), KeyboardViewController.Action(type: .Character, title: "]"), KeyboardViewController.Action(type: .Character, title: "{"),
                    KeyboardViewController.Action(type: .Character, title: "}"), KeyboardViewController.Action(type: .Character, title: "#"), KeyboardViewController.Action(type: .Character, title: "%"), KeyboardViewController.Action(type: .Character, title: "^"),
                    KeyboardViewController.Action(type: .Character, title: "*"), KeyboardViewController.Action(type: .Character, title: "+"), KeyboardViewController.Action(type: .Character, title: "=")]

let middleRowExtraSymbols = [KeyboardViewController.Action(type: .Character, title: "_", funcType: .none), KeyboardViewController.Action(type: .Character, title: "\\"), KeyboardViewController.Action(type: .Character, title: "|"),
                    KeyboardViewController.Action(type: .Character, title: "~"), KeyboardViewController.Action(type: .Character, title: "<"), KeyboardViewController.Action(type: .Character, title: ">"), KeyboardViewController.Action(type: .Character, title: "???"),
                    KeyboardViewController.Action(type: .Character, title: "???"), KeyboardViewController.Action(type: .Character, title: "??"), KeyboardViewController.Action(type: .Character, title: "???")]

let bottomRowExtraSymbols = [KeyboardViewController.Action(type: .Function, title: "", funcType: .ExtraSymbolsShift), KeyboardViewController.Action(type: .Character, title: ".", funcType: .none), KeyboardViewController.Action(type: .Character, title: ","), KeyboardViewController.Action(type: .Character, title: "?"),
                        KeyboardViewController.Action(type: .Character, title: "!"), KeyboardViewController.Action(type: .Character, title: "\'"), KeyboardViewController.Action(type: .Function, title: "", funcType: .Backspace)]

// MARK: Misc
let punctiationArray: [String] = [" ", ".", ",", "?", "!", ":", ";"]
