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
    
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    let suiteName = "group.finale-keyboard-cache"
    
    var body: some View {
        List {
            Toggle("Auto-correct words", isOn: $autocorrectWords)
            .toggleStyle(SwitchToggleStyle(tint: tintColor))
            .onChange(of: autocorrectWords) { value in
                OnChange()
            }
            Toggle("Auto-correct grammar", isOn: $autocorrectGrammar)
            .toggleStyle(SwitchToggleStyle(tint: tintColor))
            .onChange(of: autocorrectGrammar) { value in
                OnChange()
            }
            Toggle("Auto-capitalize words", isOn: $autocapitalizeWords)
            .toggleStyle(SwitchToggleStyle(tint: tintColor))
            .onChange(of: autocapitalizeWords) { value in
                OnChange()
            }
        }
        .navigationTitle("Preferences")
        .onAppear {
            Load()
        }
    }
    
    func OnChange () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(autocorrectWords, forKey: "FINALE_DEV_APP_autocorrectWords")
        userDefaults?.setValue(autocorrectGrammar, forKey: "FINALE_DEV_APP_autocorrectGrammar")
        userDefaults?.setValue(autocapitalizeWords, forKey: "FINALE_DEV_APP_autocapitalizeWords")
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        autocorrectWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        autocorrectGrammar = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        autocapitalizeWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
    }
}
