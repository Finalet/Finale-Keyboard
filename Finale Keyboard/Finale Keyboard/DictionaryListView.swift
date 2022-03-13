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
                Toggle("Learn words automatically", isOn: $autoLearnWords)
                    .toggleStyle(SwitchToggleStyle(tint: tintColor))
                    .onChange(of: autoLearnWords) { value in
                        OnChange()
                    }
            }
            Section(footer: Text("Finale can 'learn' new words. Just swipe up after typing an unrecognized word to add it to the dictionary.")) {
                ForEach(searchResults, id: \.self) { word in
                    Text(word)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Dictionary")
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
        if autoLearnWords {
            return "Turn off to stop Finale from automatically learning new words. You will still be able to add new words by swiping up."
        } else {
            return "Turn on to make Finale automatically learn new words. You will still be able to add new words by swiping up."
        }
        
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return userDictionary
        } else {
            return userDictionary.filter { $0.contains(searchText.lowercased()) }
        }
    }
    
    func delete(at offsets: IndexSet) {
        userDictionary.remove(atOffsets: offsets)
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
