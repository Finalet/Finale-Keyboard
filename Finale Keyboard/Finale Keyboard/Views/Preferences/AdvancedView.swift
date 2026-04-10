//
//  AdvancedView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI

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

