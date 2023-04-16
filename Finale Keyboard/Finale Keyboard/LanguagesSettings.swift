//
//  LanguagesSettings.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 3/10/22.
//
import SwiftUI

struct LanguagesSettings: View {
    @Binding var EN_enabled: Bool
    @Binding var RU_enabled: Bool
    
    @State var isOneLanguageOnly = false
    
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    var body: some View {
        List {
            Toggle(Localization.LanguagesScreen.english, isOn: $EN_enabled)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .disabled(isOneLanguageOnly && EN_enabled)
                .onChange(of: EN_enabled) { value in
                    OnChange()
                }
            Toggle(Localization.LanguagesScreen.russian, isOn: $RU_enabled)
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
                .disabled(isOneLanguageOnly && RU_enabled)
                .onChange(of: RU_enabled) { value in
                    OnChange()
                }
        }
        .navigationTitle(Localization.LanguagesScreen.title)
        .onAppear() {
            CheckLanguages()
        }
    }
    
    func OnChange () {
        CheckLanguages()
        SaveLanguages()
    }
    func CheckLanguages () {
        if !EN_enabled || !RU_enabled {
            isOneLanguageOnly = true
        } else {
            isOneLanguageOnly = false
        }
    }
    
    func SaveLanguages () {
        let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        userDefaults?.setValue(EN_enabled, forKey: "FINALE_DEV_APP_en_locale_enabled")
        userDefaults?.setValue(RU_enabled, forKey: "FINALE_DEV_APP_ru_locale_enabled")
    }
}
