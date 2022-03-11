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
    
    let suiteName = "group.finale-keyboard-cache"
    
    var body: some View {
        List {
            Section(footer: Text("Finale can 'learn' new words. Just swipe up after typing an unrecognized word to add it to the dictionary.")) {
                ForEach(searchResults, id: \.self) { word in
                    Text(word)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Dictionary")
        .onAppear {
            LoadDictionary()
        }
        .searchable(text: $searchText)
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return userDictionary
        } else {
            return userDictionary.filter { $0.contains(searchText) }
        }
    }
    
    func delete(at offsets: IndexSet) {
        userDictionary.remove(atOffsets: offsets)
        SaveUserDictionary()
    }
    
    func LoadDictionary () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_userDictionary") as? [String] ?? [String]()
    }
    
    func SaveUserDictionary () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(userDictionary, forKey: "FINALE_DEV_APP_userDictionary")
    }
}
