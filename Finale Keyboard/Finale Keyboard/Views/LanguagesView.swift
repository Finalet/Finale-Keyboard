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
    
    var nLanguagesEnabled: Int {  [EN_enabled, RU_enabled].filter { $0 }.count }
    
    var body: some View {
        List {
            Toggle(Localization.LanguagesScreen.english, isOn: $EN_enabled)
                .disabled(nLanguagesEnabled == 1 && EN_enabled)
            Toggle(Localization.LanguagesScreen.russian, isOn: $RU_enabled)
                .disabled(nLanguagesEnabled == 1 && RU_enabled)
        }
        .navigationTitle(Localization.LanguagesScreen.title)
    }
}
