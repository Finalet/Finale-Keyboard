//
//  LanguagesSettings.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 3/10/22.
//
import SwiftUI

struct LanguagesView: View {
    @UserDefaultState("FINALE_DEV_APP_en_locale_enabled", true) var EN_enabled: Bool
    @UserDefaultState("FINALE_DEV_APP_ru_locale_enabled", false) var RU_enabled: Bool
    @UserDefaultState("FINALE_DEV_APP_es_locale_enabled", false) var ES_enabled: Bool
    @UserDefaultState("FINALE_DEV_APP_de_locale_enabled", false) var DE_enabled: Bool
    
    var nLanguagesEnabled: Int {  [EN_enabled, RU_enabled, ES_enabled, DE_enabled].filter { $0 }.count }
    
    var body: some View {
        List {
            LanguageToggle(label: Localization.LanguagesScreen.english, isOn: $EN_enabled, nLanguagesEnabled: nLanguagesEnabled)
            LanguageToggle(label: Localization.LanguagesScreen.russian, isOn: $RU_enabled, nLanguagesEnabled: nLanguagesEnabled)
            LanguageToggle(label: Localization.LanguagesScreen.spanish, isOn: $ES_enabled, nLanguagesEnabled: nLanguagesEnabled)
            LanguageToggle(label: Localization.LanguagesScreen.german, isOn: $DE_enabled, nLanguagesEnabled: nLanguagesEnabled)
        }
        .navigationTitle(Localization.LanguagesScreen.title)
    }
}

struct LanguageToggle: View {
    let label: String
    @Binding var isOn: Bool
    
    var nLanguagesEnabled: Int
    
    var body: some View {
        Toggle(label, isOn: $isOn)
            .disabled(nLanguagesEnabled == 1 && isOn)
    }
}
