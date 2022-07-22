//
//  TutorialView.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 3/9/22.
//

import Foundation
import SwiftUI

struct DictionaryListView: View {
    @State var userDictionary = [String]()
    @State private var searchText = ""
    
    @State var autoLearnWords = true
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    let suiteName = "group.finale-keyboard-cache"
    
    var body: some View {
        List {
            Section (footer: Text(footerText)) {
                Toggle(Localization.DictionaryScreen.learnWordsAutomatically, isOn: $autoLearnWords)
                    .toggleStyle(SwitchToggleStyle(tint: tintColor))
                    .onChange(of: autoLearnWords) { value in
                        OnChange()
                    }
            }
            Section(footer: Text(Localization.DictionaryScreen.footer)) {
                ForEach(searchResults, id: \.self) { word in
                    Text(word)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle(Localization.DictionaryScreen.title)
        .onAppear {
            Load()
        }
        .searchable(text: $searchText)
    }
    
    func OnChange () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(autoLearnWords, forKey: "FINALE_DEV_APP_autoLearnWords")
    }
    
    var footerText: String {
        return autoLearnWords ? Localization.DictionaryScreen.learnWordsAutomaticallyIsOn : Localization.DictionaryScreen.learnWordsAutomaticallyIsOff
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return userDictionary.sorted()
        } else {
            return userDictionary.sorted().filter { $0.contains(searchText.lowercased()) }
        }
    }
    
    func delete(at offsets: IndexSet) {
        userDictionary.remove(at: userDictionary.firstIndex(of: searchResults[offsets.first!])!)
        SaveUserDictionary()
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_userDictionary") as? [String] ?? [String]()
        autoLearnWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autoLearnWords") as? Bool ?? true
    }
    
    func SaveUserDictionary () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(userDictionary, forKey: "FINALE_DEV_APP_userDictionary")
    }
}
