//
//  ShortcutsView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/14/23.
//

import Foundation
import SwiftUI

struct ShortcutsView: View {
    
    let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        
    @UserDefaultState("FINALE_DEV_APP_en_locale_enabled", true) var EN_enabled: Bool
    @UserDefaultState("FINALE_DEV_APP_ru_locale_enabled", false) var RU_enabled: Bool
    @UserDefaultState("FINALE_DEV_APP_es_locale_enabled", false) var ES_enabled: Bool
    @UserDefaultState("FINALE_DEV_APP_de_locale_enabled", false) var DE_enabled: Bool
    
    @State private var restoreDefaults = false
    @State private var populateEmoji = false
    
    @State var tryText: String = ""
    
    typealias Loc = Localization.Shortcuts
    
    var body: some View {
        ScrollView {
            VStack (spacing: 36) {
                Header()
                
                if EN_enabled {
                    KeyboardView(locale: .en_US, title: Localization.LanguagesScreen.english.uppercased(), restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                }
                
                if RU_enabled {
                    KeyboardView(locale: .ru_RU, title: Localization.LanguagesScreen.russian.uppercased(), restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                }
                
                if ES_enabled {
                    KeyboardView(locale: .es_ES, title: Localization.LanguagesScreen.spanish.uppercased(), restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                }
                
                if ES_enabled {
                    KeyboardView(locale: .de_DE, title: Localization.LanguagesScreen.german.uppercased(), restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                }
                
                KeyboardView(symbols: true, title: Loc.symbols.uppercased(), restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                KeyboardView(title: Loc.extraSymbols.uppercased(), restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(Loc.title)
        .toolbar {
            Menu {
                Button {
                    RestoreDefaults()
                } label: {
                    Label(Loc.restoreDefaults, systemImage: "arrow.counterclockwise")
                }
                
                Button {
                    PopulateEmoji()
                } label: {
                    Label(Loc.populateEmoji, systemImage: "heart")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .background {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
        }
        .onTapGesture {
            HideKeyboard()
        }
    }
    
    func RestoreDefaults () {
        userDefaults?.removeObject(forKey: "FINALE_DEV_APP_shortcuts")
        restoreDefaults.toggle()
    }
    func PopulateEmoji () {
        populateEmoji.toggle()
    }
    
    func HideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    struct Header: View {
        
        @State var tryText: String = ""
        
        var body: some View {
            VStack (spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    VStack (spacing: 5) {
                        HStack {
                            Text(Loc.headerTitle)
                                .font(.footnote)
                            
                            Spacer()
                        }
                        HStack {
                            Text(Loc.headerDescription)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(Color(UIColor.systemGray3))
                TextField(Localization.HomeScreen.inputFieldPlaceholder, text: $tryText)
                    .font(.subheadline)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color(UIColor.systemGray5))
            }
        }
    }
    
    struct Title: View {
        
        @State var title: String
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
            }
        }
    }
    
    struct KeyboardView: View {
        let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        
        @State var title: String
        @State var locale: Locale?
        @State var symbols = false
        
        @State var topRowShortcuts: [String]
        @State var middleRowShortcuts: [String]
        @State var bottomRowShortcuts: [String]
        
        @Binding var restoreDefaults: Bool
        @Binding var populateEmoji: Bool
        
        init (locale: Locale? = nil, symbols: Bool = false, title: String, restoreDefaults: Binding<Bool>, populateEmoji: Binding<Bool>) {
            self._locale = State(initialValue: locale)
            self._title = State(initialValue: title)
            self._restoreDefaults = restoreDefaults
            self._populateEmoji = populateEmoji
            self._symbols = State(initialValue: symbols)
            
            self._topRowShortcuts = State(initialValue: [String](repeating: "", count: (locale?.topRow ?? (symbols ? Symbols.Symbols.topRow : Symbols.ExtraSymbols.topRow)).count))
            self._middleRowShortcuts = State(initialValue: [String](repeating: "", count: (locale?.middleRow ?? (symbols ? Symbols.Symbols.middleRow : Symbols.ExtraSymbols.middleRow)).count))
            self._bottomRowShortcuts = State(initialValue: [String](repeating: "", count: (locale?.bottomRow ?? (symbols ? Symbols.Symbols.bottomRow : Symbols.ExtraSymbols.bottomRow)).count))
        }
        
        var topRowDictKeys: [String] {
            (locale?.topRow ?? (symbols ? Symbols.Symbols.topRow : Symbols.ExtraSymbols.topRow)).map({ getDictKey(forShortcutKey: $0) })
        }
        
        var middleRowDictKeys: [String] {
            (locale?.middleRow ?? (symbols ? Symbols.Symbols.middleRow : Symbols.ExtraSymbols.middleRow)).map({ getDictKey(forShortcutKey: $0) })
        }
        
        var bottomRowDictKeys: [String] {
            (locale?.bottomRow ?? (symbols ? Symbols.Symbols.bottomRow : Symbols.ExtraSymbols.bottomRow)).map({ getDictKey(forShortcutKey: $0) })
        }
        
        var body: some View {
            VStack {
                Title(title: title)
                
                HStack {
                    ForEach(0..<topRowShortcuts.count, id: \.self) { i in
                        Key(placeholder: getShortcutKeyFromDictKey(dictKey: topRowDictKeys[i]), value: $topRowShortcuts[i], onEndFocus: Save)
                    }
                }
                HStack {
                    ForEach(0..<middleRowShortcuts.count, id: \.self) { i in
                        Key(placeholder: getShortcutKeyFromDictKey(dictKey: middleRowDictKeys[i]), value: $middleRowShortcuts[i], onEndFocus: Save)
                    }
                }
                if locale != nil || symbols {
                    HStack {
                        ForEach(0..<bottomRowShortcuts.count, id: \.self) { i in
                            Key(placeholder: getShortcutKeyFromDictKey(dictKey: bottomRowDictKeys[i]), value: $bottomRowShortcuts[i], onEndFocus: Save)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            .onAppear {
                Load()
            }
            .onChange(of: restoreDefaults) { _, _ in
                Load()
            }
            .onChange(of: populateEmoji) { _, _ in
                PopulateFavoriteEmoji()
            }
        }
        
        func Save () {
            var dict = userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String : String] ?? Defaults.shortcuts
            
            SaveShortcutsToDictionary(shortcuts: &topRowShortcuts, keys: topRowDictKeys, dict: &dict)
            SaveShortcutsToDictionary(shortcuts: &middleRowShortcuts, keys: middleRowDictKeys, dict: &dict)
            SaveShortcutsToDictionary(shortcuts: &bottomRowShortcuts, keys: bottomRowDictKeys, dict: &dict)
            
            userDefaults?.setValue(dict, forKey: "FINALE_DEV_APP_shortcuts")
        }
        
        func SaveShortcutsToDictionary(shortcuts: inout [String], keys: [String], dict: inout [String : String]) {
            for i in 0..<shortcuts.count {
                shortcuts[i] = shortcuts[i].trimmingCharacters(in: .whitespaces)
                
                let key = keys[i]
                let value = shortcuts[i]
                
                if value.isEmpty {
                    dict.removeValue(forKey: key)
                } else {
                    dict.updateValue(value, forKey: key)
                }
                
                // With the 2.1.0 update, the dictionary stores unique shortcuts for each locale. Previously, the key was just "w". Now, the key is "en_US:w", to make sure there are no collisions with different languages.
                // So, to keep the dictionary clean, we remove the old, not anymore used, keys, like "W".
                let keyWithoutLocale = getShortcutKeyFromDictKey(dictKey: key)
                if keyWithoutLocale != key {
                    dict.removeValue(forKey: keyWithoutLocale)
                }
            }
        }
        
        func Load () {
            topRowShortcuts = [String](repeating: "", count: topRowDictKeys.count)
            middleRowShortcuts = [String](repeating: "", count: middleRowDictKeys.count)
            bottomRowShortcuts = [String](repeating: "", count: bottomRowDictKeys.count)
            for (key, value) in userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String:String] ?? Defaults.shortcuts {
                if let topRowIndex = topRowDictKeys.firstIndex(of: key) {
                    topRowShortcuts[topRowIndex] = value
                } else if let middleRowIndex = middleRowDictKeys.firstIndex(of: key) {
                    middleRowShortcuts[middleRowIndex] = value
                } else if let bottomRowIndex = bottomRowDictKeys.firstIndex(of: key) {
                    bottomRowShortcuts[bottomRowIndex] = value
                }
            }
        }
        
        func PopulateFavoriteEmoji () {
            if locale == nil { return }
            
            let favoriteEmoji = userDefaults?.array(forKey: "FINALE_DEV_APP_favorite_emoji") as? [String] ?? [String](repeating: "", count: 32)
            if favoriteEmoji.count < 32 { return }
            
            let topLeft1Emoji = favoriteEmoji[0]
            if topLeft1Emoji != "" { topRowShortcuts[0] = topLeft1Emoji }
            
            let topLeft2Emoji = favoriteEmoji[1]
            if topLeft2Emoji != "" { topRowShortcuts[1] = topLeft2Emoji }
            
            let topLeft3Emoji = favoriteEmoji[2]
            if topLeft3Emoji != "" { topRowShortcuts[2] = topLeft3Emoji }
            
            let topLeft4Emoji = favoriteEmoji[3]
            if topLeft4Emoji != "" { topRowShortcuts[3] = topLeft4Emoji }
            
            let topLeft5Emoji = favoriteEmoji[4]
            if topLeft5Emoji != "" { topRowShortcuts[4] = topLeft5Emoji }
            
            let midLeft1Emoji = favoriteEmoji[8]
            if midLeft1Emoji != "" { middleRowShortcuts[0] = midLeft1Emoji }
            
            let midLeft2Emoji = favoriteEmoji[9]
            if midLeft2Emoji != "" { middleRowShortcuts[1] = midLeft2Emoji }
            
            let midLeft3Emoji = favoriteEmoji[10]
            if midLeft3Emoji != "" { middleRowShortcuts[2] = midLeft3Emoji }
            
            let midLeft4Emoji = favoriteEmoji[11]
            if midLeft4Emoji != "" { middleRowShortcuts[3] = midLeft4Emoji }
            
            let midLeft5Emoji = favoriteEmoji[12]
            if midLeft5Emoji != "" { middleRowShortcuts[4] = midLeft5Emoji }
            
            let topRight1Emoji = favoriteEmoji[7]
            if topRight1Emoji != "" { topRowShortcuts[topRowDictKeys.count-1] = topRight1Emoji }
            
            let middleRight1Emoji = favoriteEmoji[15]
            if middleRight1Emoji != "" { middleRowShortcuts[middleRowDictKeys.count-1] = middleRight1Emoji }
            
            Save()
        }
        
        func getDictKey(forShortcutKey: String) -> String {
            return (locale != nil ? "\(locale!.languageCode):" : "") + forShortcutKey
        }
        func getShortcutKeyFromDictKey(dictKey: String) -> String {
            if dictKey.count > 3 && dictKey.contains(":") {
                return String(dictKey.split(separator: ":").last!)
            }
            return dictKey
        }
        
        struct Key: View {
            
            let placeholder: String
            @Binding var value: String
            
            @FocusState private var isFocused: Bool
            
            var onEndFocus: (()->())
            
            var body: some View {
                TextField(placeholder, text: $value)
                    .multilineTextAlignment(.center)
                    .truncationMode(.middle)
                    .padding(.vertical, 10)
                    .frame(minWidth: 15, maxWidth: 30 + Double(value.count) * 6)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemGray4))
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.blue, lineWidth: 2)
                                .opacity(Double(value.count))
                        }
                    }
                    .layoutPriority(value.count == 0 ? 1 : 2)
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, isFocused in
                        if !isFocused {
                            onEndFocus()
                        } else {
                            value = ""
                        }
                    }
            }
        }
    }
}
