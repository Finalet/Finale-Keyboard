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
        
    @Binding var EN_enabled: Bool
    @Binding var RU_enabled: Bool
    
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
        
        @State var topRow: [String]
        @State var middleRow: [String]
        @State var bottomRow: [String]
        
        @Binding var restoreDefaults: Bool
        @Binding var populateEmoji: Bool
        
        init (locale: Locale? = nil, symbols: Bool = false, title: String, restoreDefaults: Binding<Bool>, populateEmoji: Binding<Bool>) {
            self._locale = State(initialValue: locale)
            self._title = State(initialValue: title)
            self._restoreDefaults = restoreDefaults
            self._populateEmoji = populateEmoji
            self._symbols = State(initialValue: symbols)
            
            self._topRow = State(initialValue: [String](repeating: "", count: (locale?.topRow ?? (symbols ? Symbols.Symbols.topRow : Symbols.ExtraSymbols.topRow)).count))
            self._middleRow = State(initialValue: [String](repeating: "", count: (locale?.middleRow ?? (symbols ? Symbols.Symbols.middleRow : Symbols.ExtraSymbols.middleRow)).count))
            self._bottomRow = State(initialValue: [String](repeating: "", count: (locale?.bottomRow ?? (symbols ? Symbols.Symbols.bottomRow : Symbols.ExtraSymbols.bottomRow)).count))
        }
        
        var topRowArray: [String] {
            locale?.topRow ?? (symbols ? Symbols.Symbols.topRow : Symbols.ExtraSymbols.topRow)
        }
        
        var middleRowArray: [String] {
            locale?.middleRow ?? (symbols ? Symbols.Symbols.middleRow : Symbols.ExtraSymbols.middleRow)
        }
        
        var bottomRowArray: [String] {
            locale?.bottomRow ?? (symbols ? Symbols.Symbols.bottomRow : Symbols.ExtraSymbols.bottomRow)
        }
        
        var body: some View {
            VStack {
                Title(title: title)
                
                HStack {
                    ForEach(0..<topRow.count, id: \.self) { i in
                        Key(placeholder: topRowArray[i], value: $topRow[i], onEndFocus: Save)
                    }
                }
                HStack {
                    ForEach(0..<middleRow.count, id: \.self) { i in
                        Key(placeholder: middleRowArray[i], value: $middleRow[i], onEndFocus: Save)
                    }
                }
                if locale != nil || symbols {
                    HStack {
                        ForEach(0..<bottomRow.count, id: \.self) { i in
                            Key(placeholder: bottomRowArray[i], value: $bottomRow[i], onEndFocus: Save)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
            .onAppear {
                Load()
            }
            .onChange(of: restoreDefaults) { _ in
                Load()
            }
            .onChange(of: populateEmoji) { _ in
                PopulateFavoriteEmoji()
            }
        }
        
        func Save () {
            var dict = userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String : String] ?? Defaults.shortcuts
            
            ParseArray(array: &topRow, keys: topRowArray, dict: &dict)
            ParseArray(array: &middleRow, keys: middleRowArray, dict: &dict)
            ParseArray(array: &bottomRow, keys: bottomRowArray, dict: &dict)
            
            userDefaults?.setValue(dict, forKey: "FINALE_DEV_APP_shortcuts")
        }
        
        func ParseArray (array: inout [String], keys: [String], dict: inout [String : String]) {
            for i in 0..<array.count {
                if array[i] == "" {
                    dict.removeValue(forKey: String(keys[i]))
                } else {
                    while let first = array[i].first, first == " " {
                        array[i].removeFirst()
                    }
                    while let last = array[i].last, last == " " {
                        array[i].removeLast()
                    }
                    
                    dict[keys[i]] = array[i]
                }
            }
        }
        
        func Load () {
            topRow = [String](repeating: "", count: topRowArray.count)
            middleRow = [String](repeating: "", count: middleRowArray.count)
            bottomRow = [String](repeating: "", count: bottomRowArray.count)
            for (key, value) in userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String:String] ?? Defaults.shortcuts {
                if let topRowIndex = topRowArray.firstIndex(of: key) {
                    topRow[topRowIndex] = value
                } else if let middleRowIndex = middleRowArray.firstIndex(of: key) {
                    middleRow[middleRowIndex] = value
                } else if let bottomRowIndex = bottomRowArray.firstIndex(of: key) {
                    bottomRow[bottomRowIndex] = value
                }
            }
        }
        
        func PopulateFavoriteEmoji () {
            if locale == nil { return }
            
            let favoriteEmoji = userDefaults?.array(forKey: "FINALE_DEV_APP_favorite_emoji") as? [String] ?? [String](repeating: "", count: 32)
            if favoriteEmoji.count < 32 { return }
            
            let topLeft1Emoji = favoriteEmoji[0]
            if topLeft1Emoji != "" { topRow[0] = topLeft1Emoji }
            
            let topLeft2Emoji = favoriteEmoji[1]
            if topLeft2Emoji != "" { topRow[1] = topLeft2Emoji }
            
            let topLeft3Emoji = favoriteEmoji[2]
            if topLeft3Emoji != "" { topRow[2] = topLeft3Emoji }
            
            let topLeft4Emoji = favoriteEmoji[3]
            if topLeft4Emoji != "" { topRow[3] = topLeft4Emoji }
            
            let topLeft5Emoji = favoriteEmoji[4]
            if topLeft5Emoji != "" { topRow[4] = topLeft5Emoji }
            
            let midLeft1Emoji = favoriteEmoji[8]
            if midLeft1Emoji != "" { middleRow[0] = midLeft1Emoji }
            
            let midLeft2Emoji = favoriteEmoji[9]
            if midLeft2Emoji != "" { middleRow[1] = midLeft2Emoji }
            
            let midLeft3Emoji = favoriteEmoji[10]
            if midLeft3Emoji != "" { middleRow[2] = midLeft3Emoji }
            
            let midLeft4Emoji = favoriteEmoji[11]
            if midLeft4Emoji != "" { middleRow[3] = midLeft4Emoji }
            
            let midLeft5Emoji = favoriteEmoji[12]
            if midLeft5Emoji != "" { middleRow[4] = midLeft5Emoji }
            
            let topRight1Emoji = favoriteEmoji[7]
            if topRight1Emoji != "" { topRow[topRowArray.count-1] = topRight1Emoji }
            
            let middleRight1Emoji = favoriteEmoji[15]
            if middleRight1Emoji != "" { middleRow[middleRowArray.count-1] = middleRight1Emoji }
            
            Save()
        }
        
        struct Key: View {
            
            @State var placeholder: String
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
                    .onChange(of: isFocused) { isFocused in
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

struct ShortcutsView_Preview: PreviewProvider {
    static var previews: some View {
        ShortcutsView(EN_enabled: .constant(true), RU_enabled: .constant(true))
    }
}
