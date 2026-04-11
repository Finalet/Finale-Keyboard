//
//  PreferencesView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 3/13/22.
//

import Foundation
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var iapManager: InAppPurchasesManager

    @UseUserDefaultState("FINALE_DEV_APP_autocorrectWords", true) var autocorrectWords
    @UseUserDefaultState("FINALE_DEV_APP_autocorrectGrammar", true) var autocorrectGrammar
    @UseUserDefaultState("FINALE_DEV_APP_autocapitalizeWords", true) var autocapitalizeWords
    
    @UseUserDefaultState("FINALE_DEV_APP_isTypingHapticEnabled", true) var isTypingHapticEnabled
    @UseUserDefaultState("FINALE_DEV_APP_isGesturesHapticEnabled", true) var isGesturesHapticEnabled

    @UseUserDefaultState("FINALE_DEV_APP_isSpacebarEnabled", false) var isSpacebarEnabled
    @UseUserDefaultState("FINALE_DEV_APP_spacebarAutocorrect", false) var spacebarAutocorrect
    @State var showSpacebarPurchase = false
    
    typealias Localize = Localization.PreferencesScreen
    
    var body: some View {
        List {
            Section {
                Toggle(Localize.autocorrectWords, isOn: $autocorrectWords)
                Toggle(Localize.autocorrectGrammar, isOn: $autocorrectGrammar)
                Toggle(Localize.autocapitalizeWords, isOn: $autocapitalizeWords)
            }
            Section {
                Toggle(Localize.gesturesHapticFeedback, isOn: $isGesturesHapticEnabled)
                Toggle(Localize.typingHapticFeedback, isOn: $isTypingHapticEnabled)
            }
            Section {
                Toggle("Spacebar", isOn: $isSpacebarEnabled.animation())
                    .onChange(of: isSpacebarEnabled) { _, value in
                        if value && !iapManager.isSpacebarUnlocked {
                            isSpacebarEnabled = false
                            showSpacebarPurchase = true
                        } else {
                            isSpacebarEnabled = value
                        }
                    }
                if isSpacebarEnabled {
                    Toggle("Spacebar Autocorrect", isOn: $spacebarAutocorrect)
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
        .environmentObject(iapManager)
    }
}

@propertyWrapper
struct UseUserDefaultState<Value>: DynamicProperty {
    @State private var value: Value

    private let key: String
    private let defaultValue: Value
    private let store: UserDefaults?

    init(
        _ key: String,
        _ defaultValue: Value,
        store: UserDefaults? = UserDefaults(suiteName: "group.finale-keyboard-cache")
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
        _value = State(initialValue: store?.value(forKey: key) as? Value ?? defaultValue)
    }

    var wrappedValue: Value {
        get {
            self.value
        }
        nonmutating set {
            self.value = newValue
            self.store?.setValue(newValue, forKey: key)
        }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { newValue, transaction in
                withTransaction(transaction) {
                    wrappedValue = newValue
                }
            }
        )
    }
}


@propertyWrapper
struct UseUserDefault<Value> {
    private let key: String
    private let defaultValue: Value
    private let store: UserDefaults?

    init(
        _ key: String,
        _ defaultValue: Value,
        store: UserDefaults? = UserDefaults(suiteName: "group.finale-keyboard-cache")
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = store
    }

    var wrappedValue: Value {
        get {
            self.store?.value(forKey: key) as? Value ?? defaultValue
        }
        nonmutating set {
            self.store?.setValue(newValue, forKey: key)
        }
    }
}