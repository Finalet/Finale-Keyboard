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
    
    @State var showSpacebarPurchase = false
    @State var isSpacebarEnabled = false
    @State var spacebarAutocorrect = false
    
    @State var isTypingHapticEnabled = false
    @State var isGesturesHapticEnabled = true
    
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    let suiteName = "group.finale-keyboard-cache"
    
    typealias Localize = Localization.PreferencesScreen
    
    var body: some View {
        List {
            Section {
                Toggle(Localize.autocorrectWords, isOn: $autocorrectWords)
                .onChange(of: autocorrectWords) { value in
                    OnChange()
                }
                Toggle(Localize.autocorrectGrammar, isOn: $autocorrectGrammar)
                .onChange(of: autocorrectGrammar) { value in
                    OnChange()
                }
                Toggle(Localize.autocapitalizeWords, isOn: $autocapitalizeWords)
                .onChange(of: autocapitalizeWords) { value in
                    OnChange()
                }
            }
            Section {
                Toggle("Spacebar", isOn: $isSpacebarEnabled.animation())
                .onChange(of: isSpacebarEnabled) { value in
                    if value {
                        isSpacebarEnabled = false
                        showSpacebarPurchase = true
                    } else {
                        OnChange()
                    }
                }
                if isSpacebarEnabled {
                    Toggle("Spacebar Autocorrect", isOn: $spacebarAutocorrect)
                    .onChange(of: spacebarAutocorrect) { value in
                        OnChange()
                    }
                }
            }
            Section {
                Toggle(Localize.gesturesHapticFeedback, isOn: $isGesturesHapticEnabled)
                .onChange(of: isGesturesHapticEnabled) { value in
                    OnChange()
                }
                Toggle(Localize.typingHapticFeedback, isOn: $isTypingHapticEnabled)
                .onChange(of: isTypingHapticEnabled) { value in
                    OnChange()
                }
            }
            Section {
                ListNavigationLink(destination: DynamicTouchZonesView()) {
                    Text(Localize.DynamicTouchZones.pageTitle)
                }
                ListNavigationLink(destination: PunctuationView()) {
                    Text(Localize.Punctuation.pageTitle)
                }
                ListNavigationLink(destination: AdvancedView()) {
                    Text(Localize.Advanced.pageTitle)
                }
            }
        }
        .sheet(isPresented: $showSpacebarPurchase) {
            SpacebarPurchaseView()
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
        userDefaults?.setValue(isSpacebarEnabled, forKey: "FINALE_DEV_APP_isSpacebarEnabled")
        userDefaults?.setValue(spacebarAutocorrect, forKey: "FINALE_DEV_APP_spacebarAutocorrect")
        userDefaults?.setValue(isTypingHapticEnabled, forKey: "FINALE_DEV_APP_isTypingHapticEnabled")
        userDefaults?.setValue(isGesturesHapticEnabled, forKey: "FINALE_DEV_APP_isGesturesHapticEnabled")
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        autocorrectWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        autocorrectGrammar = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        autocapitalizeWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
        isSpacebarEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isSpacebarEnabled") as? Bool ?? false
        spacebarAutocorrect = userDefaults?.value(forKey: "FINALE_DEV_APP_spacebarAutocorrect") as? Bool ?? false
        isTypingHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isTypingHapticEnabled") as? Bool ?? false
        isGesturesHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isGesturesHapticEnabled") as? Bool ?? true
    }
}
