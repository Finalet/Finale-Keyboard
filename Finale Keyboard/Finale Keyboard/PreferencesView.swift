//
//  PreferencesView.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 3/13/22.
//

import Foundation
import SwiftUI

struct PreferencesView: View {
    @State var autocorrectWords = true
    @State var autocorrectGrammar = true
    @State var autocapitalizeWords = true
    @State var isTypingHapticEnabled = false
    @State var isGesturesHapticEnabled = false
    
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    let suiteName = "group.finale-keyboard-cache"
    
    typealias Localize = Localization.PreferencesScreen
    
    var body: some View {
        List {
            Section {
                Toggle(Localize.autocorrectWords, isOn: $autocorrectWords)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .onChange(of: autocorrectWords) { value in
                    OnChange()
                }
                Toggle(Localize.autocorrectGrammar, isOn: $autocorrectGrammar)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .onChange(of: autocorrectGrammar) { value in
                    OnChange()
                }
                Toggle(Localize.autocapitalizeWords, isOn: $autocapitalizeWords)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .onChange(of: autocapitalizeWords) { value in
                    OnChange()
                }
            }
            Section {
                Toggle(Localize.gesturesHapticFeedback, isOn: $isGesturesHapticEnabled)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .onChange(of: isGesturesHapticEnabled) { value in
                    OnChange()
                }
                Toggle(Localize.typingHapticFeedback, isOn: $isTypingHapticEnabled)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .onChange(of: isTypingHapticEnabled) { value in
                    OnChange()
                }
            }
            Section {
                ListNavigationLink(destination: PreferencesPunctuationView()) {
                    Text(Localize.Punctuation.pageTitle)
                }
                .frame(height: 30)
                ListNavigationLink(destination: PreferencesShortcutsView()) {
                    Text("Shortcuts")
                }
                .frame(height: 30)
            }
            Section {
                ListNavigationLink(destination: AdvancedView()) {
                    Text(Localize.Advanced.pageTitle)
                }
                .frame(height: 30)
            }
        }
        .navigationTitle(Localize.title)
        .onAppear {
            Load()
        }
    }
    
    func OnChange () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(autocorrectWords, forKey: "FINALE_DEV_APP_autocorrectWords")
        userDefaults?.setValue(autocorrectGrammar, forKey: "FINALE_DEV_APP_autocorrectGrammar")
        userDefaults?.setValue(autocapitalizeWords, forKey: "FINALE_DEV_APP_autocapitalizeWords")
        userDefaults?.setValue(isTypingHapticEnabled, forKey: "FINALE_DEV_APP_isTypingHapticEnabled")
        userDefaults?.setValue(isGesturesHapticEnabled, forKey: "FINALE_DEV_APP_isGesturesHapticEnabled")
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        autocorrectWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        autocorrectGrammar = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        autocapitalizeWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
        isTypingHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isTypingHapticEnabled") as? Bool ?? false
        isGesturesHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isGesturesHapticEnabled") as? Bool ?? true
    }
}


struct PreferencesPunctuationView: View {
    typealias Localize = Localization.PreferencesScreen.Punctuation
    let suiteName = "group.finale-keyboard-cache"
    
    @State var punctuationArray = Defaults.punctuation
    
    let punctuationOptions = [".", ",", "?", "!", ":", ";", "-", "@", "*", "\"", "/", "\\", "|", "(", ")", "[", "]", "{", "}"]
    
    var body: some View {
        Form {
            Section {
                ForEach(0..<6) { i in
                    Picker(getOptionTitle(i), selection: $punctuationArray[i+1]) {
                        ForEach(punctuationOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .onChange(of: punctuationArray) { value in
                        Save()
                    }
                }
            }
            Section {
                Button(action: {
                    Reset()
                }, label: {
                    Text(Localize.reset)
                })
            }
        }
        .navigationTitle(Localize.pageTitle)
        .onAppear {
            Load()
        }
    }
    
    func getOptionTitle(_ index: Int) -> String {
        if index == 0 { return Localize.first }
        if index == 1 { return Localize.second }
        if index == 2 { return Localize.third }
        if index == 3 { return Localize.fourth }
        if index == 4 { return Localize.fifth }
        if index == 5 { return Localize.sixth }
        return Localize.seventh
    }
    
    func Reset() {
        punctuationArray = Defaults.punctuation
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        punctuationArray = userDefaults?.value(forKey: "FINALE_DEV_APP_punctuationArray") as? [String] ?? Defaults.punctuation
    }
    func Save() {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(punctuationArray, forKey: "FINALE_DEV_APP_punctuationArray")
    }
}

struct PreferencesShortcutsView: View {
//    typealias Localize = Localization.PreferencesScreen.Punctuation
    
    @State var array = [Shortcut]()
    
    let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
    
    var body: some View {
        Form {
            Section (footer: Text("Swipe down on a selected key to type a corresponding shortcut.")) {
                ForEach(0..<array.count, id: \.self) { i in
                    HStack {
                        TextField("Key", text: $array[i].key)
                            .textInputAutocapitalization(.never)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Shortcut", text: $array[i].value)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .onDelete(perform: delete)
                Button {
                    withAnimation {
                        array.append(Shortcut(key: "", value: ""))
                    }
                } label: {
                    Label("Add shortcut", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Shortcuts")
        .onAppear {
            Load()
        }
        .onChange(of: array) { newVal in
            for i in 0..<array.count {
                if array[i].key.count > 1 {
                    array[i].key.removeLast()
                }
                while let first = array[i].value.first, first == " " {
                    array[i].value.removeFirst()
                }
                while let last = array[i].value.last, last == " " {
                    array[i].value.removeLast()
                }
                array[i].key = array[i].key.lowercased()
            }
            Save()
        }
    }
    
    func Load () {
        for (key, value) in userDefaults?.value(forKey: "FINALE_DEV_APP_shortcuts") as? [String:String] ?? Defaults.shortcuts {
            array.append(Shortcut(key: key, value: value))
        }
        array = array.sorted { $0.key < $1.key }
    }
    func Save() {
        var dict = [String : String]()
        array.forEach {
            if $0.key == "" || $0.value == "" {
                dict.removeValue(forKey: $0.key)
                return
            }
            
            dict[$0.key] = $0.value
        }
        userDefaults?.setValue(dict, forKey: "FINALE_DEV_APP_shortcuts")
    }
    
    func delete(at offsets: IndexSet) {
        array.remove(atOffsets: offsets)
    }
    
    struct Shortcut: Equatable {
        var key: String
        var value: String
    }
}

struct AdvancedView: View {
    typealias Localize = Localization.PreferencesScreen.Advanced
    
    let suiteName = "group.finale-keyboard-cache"
    
    @State var wordsOneTimeUse: Int
    @State var wordsTwoTimeUse: Int
    @State var totalWords: Int
    
    init () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        let learningWordsDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_learningWordsDictionary") as?  Dictionary<String, Int> ?? [String:Int]()
        
        var x = 0
        var y = 0
        for (_, value) in learningWordsDictionary {
            if value == 1 {
                x += 1
            } else if value == 2 {
                y += 1
            }
        }
        wordsOneTimeUse = x
        wordsTwoTimeUse = y
        totalWords = learningWordsDictionary.count
    }
    
    var body: some View {
        Form {
            Section (header: Text(Localize.sectionHeader), footer: Text("\(Localize.totalWords): \(totalWords)")) {
                HStack {
                    Text(Localize.wordsOneUse)
                    Spacer()
                    Text(wordsOneTimeUse.description)
                        .foregroundColor(.gray)
                }
                HStack {
                    Text(Localize.wordsTwoUse)
                    Spacer()
                    Text(wordsTwoTimeUse.description)
                        .foregroundColor(.gray)
                }
            }
            Section {
                Button(action: {
                    CleanWords(nUses: 1)
                }, label: {
                    Text(Localize.cleanWordsOneUse)
                })
                Button(action: {
                    CleanWords(nUses: 2)
                }, label: {
                    Text(Localize.cleanWordsTwoUse)
                })
            }
        }
        .navigationTitle(Localize.pageTitle)
    }
    
    func CleanWords(nUses: Int) {
        let userDefaults = UserDefaults(suiteName: suiteName)
        
        var learningWordsDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_learningWordsDictionary") as?  Dictionary<String, Int> ?? [String:Int]()
        
        for (key, value) in learningWordsDictionary {
            if value == nUses {
                learningWordsDictionary.removeValue(forKey: key)
            }
        }
        
        userDefaults?.setValue(learningWordsDictionary, forKey: "FINALE_DEV_APP_learningWordsDictionary")
        
        wordsOneTimeUse = 0
        wordsTwoTimeUse = 0
        totalWords = learningWordsDictionary.count
        for (_, value) in learningWordsDictionary {
            if value == 1 {
                wordsOneTimeUse += 1
            } else if value == 2 {
                wordsTwoTimeUse += 1
            }
        }
    }
}
