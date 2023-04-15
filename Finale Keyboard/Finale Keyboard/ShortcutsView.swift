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
    
    var body: some View {
        ScrollView {
            VStack (spacing: 36) {
                HighlightText(text: "Swipe down on a key to trigger its shortcut", icon: "lightbulb.fill")
                
                if EN_enabled {
                    KeyboardView(locale: .en_US, title: "ENGLISH", restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                }
                
                if RU_enabled {
                    KeyboardView(locale: .ru_RU, title: "RUSSIAN", restoreDefaults: $restoreDefaults, populateEmoji: $populateEmoji)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Shortcuts")
        .toolbar {
            Menu {
                Button {
                    RestoreDefaults()
                } label: {
                    Label("Restore Defaults", systemImage: "arrow.counterclockwise")
                }
                
                Button {
                    PopulateEmoji()
                } label: {
                    Label("Populate Emoji", systemImage: "heart")
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
    
    struct HighlightText: View {
        
        @State var text: String
        @State var icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                Text(text)
                    .font(.footnote)
                Spacer()
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
        @State var locale: Locale
        
        @State var topRow: [String]
        @State var middleRow: [String]
        @State var bottomRow: [String]
        
        @Binding var restoreDefaults: Bool
        @Binding var populateEmoji: Bool
        
        init (locale: Locale, title: String, restoreDefaults: Binding<Bool>, populateEmoji: Binding<Bool>) {
            self._locale = State(initialValue: locale)
            self._title = State(initialValue: title)
            self._topRow = State(initialValue: [String](repeating: "", count: locale.topRow.count) )
            self._middleRow = State(initialValue: [String](repeating: "", count: locale.middleRow.count) )
            self._bottomRow = State(initialValue: [String](repeating: "", count: locale.bottomRow.count) )
            self._restoreDefaults = restoreDefaults
            self._populateEmoji = populateEmoji
        }
        
        var body: some View {
            VStack {
                Title(title: title)
                
                HStack {
                    ForEach(0..<topRow.count, id: \.self) { i in
                        Key(placeholder: locale.topRow[i], value: $topRow[i], onEndFocus: Save)
                    }
                }
                HStack {
                    ForEach(0..<middleRow.count, id: \.self) { i in
                        Key(placeholder: locale.middleRow[i], value: $middleRow[i], onEndFocus: Save)
                    }
                }
                HStack {
                    ForEach(0..<bottomRow.count, id: \.self) { i in
                        Key(placeholder: locale.bottomRow[i], value: $bottomRow[i], onEndFocus: Save)
                    }
                }
                .padding(.horizontal, 40)
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
            
            ParseArray(array: &topRow, keys: locale.topRow, dict: &dict)
            ParseArray(array: &middleRow, keys: locale.middleRow, dict: &dict)
            ParseArray(array: &bottomRow, keys: locale.bottomRow, dict: &dict)
            
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
            topRow = [String](repeating: "", count: locale.topRow.count)
            middleRow = [String](repeating: "", count: locale.middleRow.count)
            bottomRow = [String](repeating: "", count: locale.bottomRow.count)
            for (key, value) in userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String:String] ?? Defaults.shortcuts {
                if let keyLocale = Locale.getLocale(forString: key), keyLocale == locale {
                    if let topRowIndex = keyLocale.topRow.firstIndex(of: key) {
                        topRow[topRowIndex] = value
                    } else if let middleRowIndex = keyLocale.middleRow.firstIndex(of: key) {
                        middleRow[middleRowIndex] = value
                    } else if let bottomRowIndex = keyLocale.bottomRow.firstIndex(of: key) {
                        bottomRow[bottomRowIndex] = value
                    }
                }
            }
        }
        
        func PopulateFavoriteEmoji () {
            let favoriteEmoji = userDefaults?.array(forKey: "FINALE_DEV_APP_favorite_emoji") as? [String] ?? [String](repeating: "", count: 32)
            if favoriteEmoji.count < 32 { return }
            
            let topLeftEmoji = favoriteEmoji[0]
            if topLeftEmoji != "" { topRow[0] = topLeftEmoji }
            
            let topLeftSecondaryEmoji = favoriteEmoji[1]
            if topLeftSecondaryEmoji != "" { topRow[1] = topLeftSecondaryEmoji }
            
            let midLeftEmoji = favoriteEmoji[8]
            if midLeftEmoji != "" { middleRow[0] = midLeftEmoji }
            
            let midLeftSecondaryEmoji = favoriteEmoji[9]
            if midLeftSecondaryEmoji != "" { middleRow[1] = midLeftSecondaryEmoji }
            
            let topRightEmoji = favoriteEmoji[7]
            if topRightEmoji != "" { topRow[locale.topRow.count-1] = topRightEmoji }
            
            let middleRightEmoji = favoriteEmoji[15]
            if middleRightEmoji != "" { middleRow[locale.middleRow.count-1] = middleRightEmoji }
            
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
