//
//  QuickPunctuation.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI

struct PunctuationView: View {
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
