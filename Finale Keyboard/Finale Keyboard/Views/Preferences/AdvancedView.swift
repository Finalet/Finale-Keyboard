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
    
    @UserDefaultState("FINALE_DEV_APP_learningWordsDictionary", [String:Int]()) var dictionary: [String:Int]
    let suiteName = "group.finale-keyboard-cache"
    
    var wordsOneTimeUse: Int { dictionary.count(where: { $0.value == 1 }) }
    var wordsTwoTimeUse: Int { dictionary.count(where: { $0.value == 2 }) }
    var totalWords: Int { dictionary.count }
    
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
        self.dictionary = dictionary.filter({ $0.value != nUses })
    }
}

