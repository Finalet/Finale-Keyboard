//
//  Locales.swift
//  Keyboard
//
//  Created by Grant Oganyan on 2/3/22.
//

import Foundation

// MARK: en_US
let topRowActions_en = [
    Action(type: .Character, title: "q"),
    Action(type: .Character, title: "w"),
    Action(type: .Character, title: "e"),
    Action(type: .Character, title: "r"),
    Action(type: .Character, title: "t"),
    Action(type: .Character, title: "y"),
    Action(type: .Character, title: "u"),
    Action(type: .Character, title: "i"),
    Action(type: .Character, title: "o"),
    Action(type: .Character, title: "p")]
let middleRowActions_en = [
    Action(type: .Character, title: "a"),
    Action(type: .Character, title: "s"),
    Action(type: .Character, title: "d"),
    Action(type: .Character, title: "f"),
    Action(type: .Character, title: "g"),
    Action(type: .Character, title: "h"),
    Action(type: .Character, title: "j"),
    Action(type: .Character, title: "k"),
    Action(type: .Character, title: "l")]
let bottomRowActions_en = [
    Action(type: .Function, title: "", funcType: .Shift),
    Action(type: .Character, title: "z"),
    Action(type: .Character, title: "x"),
    Action(type: .Character, title: "c"),
    Action(type: .Character, title: "v"),
    Action(type: .Character, title: "b"),
    Action(type: .Character, title: "n"),
    Action(type: .Character, title: "m"),
    Action(type: .Function, title: "", funcType: .Backspace)]

let bottomRowActionsEmojiSearch_en = [
    Action(type: .Function, title: "", funcType: .Back),
    Action(type: .Character, title: "z"),
    Action(type: .Character, title: "x"),
    Action(type: .Character, title: "c"),
    Action(type: .Character, title: "v"),
    Action(type: .Character, title: "b"),
    Action(type: .Character, title: "n"),
    Action(type: .Character, title: "m"),
    Action(type: .Function, title: "", funcType: .Backspace)]

// MARK: ru_RU
let topRowActions_ru = [
    Action(type: .Character, title: "й"),
    Action(type: .Character, title: "ц"),
    Action(type: .Character, title: "у"),
    Action(type: .Character, title: "к"),
    Action(type: .Character, title: "е"),
    Action(type: .Character, title: "н"),
    Action(type: .Character, title: "г"),
    Action(type: .Character, title: "ш"),
    Action(type: .Character, title: "щ"),
    Action(type: .Character, title: "з"),
    Action(type: .Character, title: "х")]
let middleRowActions_ru = [
    Action(type: .Character, title: "ф"),
    Action(type: .Character, title: "ы"),
    Action(type: .Character, title: "в"),
    Action(type: .Character, title: "а"),
    Action(type: .Character, title: "п"),
    Action(type: .Character, title: "р"),
    Action(type: .Character, title: "о"),
    Action(type: .Character, title: "л"),
    Action(type: .Character, title: "д"),
    Action(type: .Character, title: "ж"),
    Action(type: .Character, title: "э")]
let bottomRowActions_ru = [
    Action(type: .Function, title: "", funcType: .Shift), Action(type: .Character, title: "я"),
    Action(type: .Character, title: "ч"),
    Action(type: .Character, title: "с"),
    Action(type: .Character, title: "м"),
    Action(type: .Character, title: "и"),
    Action(type: .Character, title: "т"),
    Action(type: .Character, title: "ь"),
    Action(type: .Character, title: "б"),
    Action(type: .Character, title: "ю"),
    Action(type: .Function, title: "", funcType: .Backspace)]

//MARK: Symbols
let topRowSymbols = [
    Action(type: .Character, title: "1", funcType: .none),
    Action(type: .Character, title: "2"),
    Action(type: .Character, title: "3"),
    Action(type: .Character, title: "4"),
    Action(type: .Character, title: "5"),
    Action(type: .Character, title: "6"),
    Action(type: .Character, title: "7"),
    Action(type: .Character, title: "8"),
    Action(type: .Character, title: "9"),
    Action(type: .Character, title: "0")]

let middleRowSymbols = [
    Action(type: .Character, title: "-", funcType: .none), Action(type: .Character, title: "/"),
    Action(type: .Character, title: ":"),
    Action(type: .Character, title: ";"),
    Action(type: .Character, title: "("),
    Action(type: .Character, title: ")"),
    Action(type: .Character, title: "$"),
    Action(type: .Character, title: "&"),
    Action(type: .Character, title: "@"),
    Action(type: .Character, title: "\"")]

let bottomRowSymbols = [
    Action(type: .Function, title: "", funcType: .SymbolsShift),
    Action(type: .Character, title: ".", funcType: .none),
    Action(type: .Character, title: ","),
    Action(type: .Character, title: "?"),
    Action(type: .Character, title: "!"),
    Action(type: .Character, title: "\'"),
    Action(type: .Function, title: "", funcType: .Backspace)]

//MARK: Extra Symbols
let topRowExtraSymbols = [
    Action(type: .Character, title: "[", funcType: .none),
    Action(type: .Character, title: "]"),
    Action(type: .Character, title: "{"),
    Action(type: .Character, title: "}"),
    Action(type: .Character, title: "#"),
    Action(type: .Character, title: "%"),
    Action(type: .Character, title: "^"),
    Action(type: .Character, title: "*"),
    Action(type: .Character, title: "+"),
    Action(type: .Character, title: "=")]

let middleRowExtraSymbols = [
    Action(type: .Character, title: "_", funcType: .none),
    Action(type: .Character, title: "\\"),
    Action(type: .Character, title: "|"),
    Action(type: .Character, title: "~"),
    Action(type: .Character, title: "<"),
    Action(type: .Character, title: ">"),
    Action(type: .Character, title: "₽"),
    Action(type: .Character, title: "€"),
    Action(type: .Character, title: "£"),
    Action(type: .Character, title: "•")]

let bottomRowExtraSymbols = [
    Action(type: .Function, title: "", funcType: .ExtraSymbolsShift),
    Action(type: .Character, title: ".", funcType: .none),
    Action(type: .Character, title: ","),
    Action(type: .Character, title: "?"),
    Action(type: .Character, title: "!"),
    Action(type: .Character, title: "\'"),
    Action(type: .Function, title: "", funcType: .Backspace)]

// MARK: Misc
var punctuationArray: [String] = Defaults.defaultPunctuation
