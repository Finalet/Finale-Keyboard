//
//  PreferencesView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 3/13/22.
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
                ListNavigationLink(destination: DynamicTapZones()) {
                    Text("Dynamic Tap Zones")
                }
                .frame(height: 30)
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

struct DynamicTapZones: View {
    
    let suiteName = "group.finale-keyboard-cache"
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    @State var isDynamicTapZonesEnabled: Bool = false
    
    @State var loadingStatus: String? = nil
    
    var shouldLoadNGrams: Bool { return Ngrams.shared.totalNgramsLoaded == 0 }
    
    var body: some View {
        Form {
            Section {
                Toggle("Dynamic tap zones", isOn: $isDynamicTapZonesEnabled.animation())
                    .toggleStyle(SwitchToggleStyle(tint: tintColor))
                    .onChange(of: isDynamicTapZonesEnabled) { value in
                        OnChange()
                    }
            }
            if isDynamicTapZonesEnabled {
                Section (footer: Text("\(shouldLoadNGrams ? "Loading" : "Deleting") can take up to a minute. Do not leave this page until it is done.")) {
                    TextRow(label: "Loaded n-grams", value: Ngrams.shared.totalNgramsLoaded)
                    Button(action: {
                        if shouldLoadNGrams {
                            Ngrams.shared.LoadNgramsToCoreData() { status, isDone in
                                loadingStatus = isDone ? nil : status
                            }
                        } else {
                            Ngrams.shared.DeleteAllNgrams() { status, isDone in
                                loadingStatus = isDone ? nil : status
                            }
                        }
                    }, label: {
                        Text(loadingStatus ?? (shouldLoadNGrams ? "Load dictionary" : "Clear dictionary"))
                    })
                    .disabled(loadingStatus != nil)
                }
            }
        }
        .navigationTitle("Dynamic Tap Zones")
        .onAppear {
            Load()
        }
    }
    
    @ViewBuilder
    func TextRow(label: String, value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .foregroundColor(.gray)
        }
    }
    
    func OnChange () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(isDynamicTapZonesEnabled, forKey: "FINALE_DEV_APP_isDynamicTapZonesEnabled")
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        isDynamicTapZonesEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isDynamicTapZonesEnabled") as? Bool ?? false
    }
}
