//
//  PreferencesView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 3/13/22.
//

import Foundation
import SwiftUI
import AudioToolbox

struct PreferencesView: View {
    @UserDefaultState("FINALE_DEV_APP_autocorrectWords", true) var autocorrectWords
    @UserDefaultState("FINALE_DEV_APP_autocorrectGrammar", true) var autocorrectGrammar
    @UserDefaultState("FINALE_DEV_APP_autocapitalizeWords", true) var autocapitalizeWords
    
    @UserDefaultState("FINALE_DEV_APP_isTypingHapticEnabled", true) var isTypingHapticEnabled
    @UserDefaultState("FINALE_DEV_APP_isGesturesHapticEnabled", true) var isGesturesHapticEnabled
    
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
            SpacebarSection()
            Section {
                ListNavigationLink(destination: DynamicTouchZonesView()) {
                    Label(title: {
                        Text(Localize.DynamicTouchZones.pageTitle)
                    }, icon: {
                        Image(systemName: "rectangle.and.hand.point.up.left")
                    })
                }
                ListNavigationLink(destination: PunctuationView()) {
                    Label(title: {
                        Text(Localize.Punctuation.pageTitle)
                    }, icon: {
                        Image(systemName: "exclamationmark.questionmark")
                    })
                }
                ListNavigationLink(destination: AdvancedView()) {
                    Label(title: {
                        Text(Localize.Advanced.pageTitle)
                    }, icon: {
                        Image(systemName: "gearshape.2")
                    })
                }
            }
        }
        .navigationTitle(Localize.title)
    }
}

struct SpacebarSection: View {
    @EnvironmentObject var iapManager: InAppPurchasesManager
    
    @UserDefaultState("FINALE_DEV_APP_isSpacebarEnabled", false) var isSpacebarEnabled
    @UserDefaultState("FINALE_DEV_APP_spacebarAutocorrect", false) var spacebarAutocorrect
    
    @State var spacebarTaps: Int = 0
    @State var lastSpacebarTapTime: Date?
    @State var showSpacebarPurchase = false
    @State var textOffset = CGSize(width: 0, height: 0)
    @State var textScale = 1.0
    @State var fontWeight = Font.Weight.regular
    
    typealias Localize = Localization.PreferencesScreen
    
    var body: some View {
        Section {
            Toggle(isOn: $isSpacebarEnabled) {
                Text(Localize.spacebar)
                    .offset(textOffset)
                    .scaleEffect(textScale)
                    .fontWeight(fontWeight)
            }
            .onChange(of: isSpacebarEnabled) { _, value in
                if value && !iapManager.isSpacebarUnlocked {
                    isSpacebarEnabled = false
                    showSpacebarPurchase = true
                } else {
                    isSpacebarEnabled = value
                }
            }
            if isSpacebarEnabled {
                Toggle(Localize.spacebarAutocorrect, isOn: $spacebarAutocorrect)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            SpacebarTap()
        }
        .environmentObject(iapManager)
        .sheet(isPresented: $showSpacebarPurchase) {
            SpacebarPurchaseView(onSpacebarActivated: {
                UnlockSpacebar()
            })
        }
    }
    
    func SpacebarTap () {
        if iapManager.isSpacebarUnlocked { return }
        
        let now = Date()
        if let lastSpacebarTapTime = lastSpacebarTapTime, now.timeIntervalSince(lastSpacebarTapTime) > 0.5 {
            spacebarTaps = 0
        }
        
        spacebarTaps += 1
        lastSpacebarTapTime = now
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.1)) {
                let x: CGFloat = CGFloat.random(in: -10...50)
                let y: CGFloat = CGFloat.random(in: -10...10)
                textOffset = CGSize(width: textOffset.width + x, height: textOffset.height + y)
                textScale += 0.15
                fontWeight = .medium
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let lastSpacebarTapTime = lastSpacebarTapTime, Date().timeIntervalSince(lastSpacebarTapTime) < 0.1 { return }
            withAnimation(.easeOut(duration: 0.5)) {
                textOffset = .zero
                textScale = 1
                fontWeight = .regular
            }
        }
        
        if spacebarTaps > 40 {
            UnlockSpacebar()
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    func UnlockSpacebar() {
        iapManager.isSpacebarUnlocked = true
        isSpacebarEnabled = true
    }
}

@propertyWrapper
struct UserDefaultState<Value>: DynamicProperty {
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
            DispatchQueue.main.async { value = self.store?.value(forKey: key) as? Value ?? defaultValue } // Reading this value from UserDefaults becasue otherwise it resets to `defaultValue` when view reappears.
            return value
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
struct UserDefault<Value> {
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
        set {
            self.store?.setValue(newValue, forKey: key)
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(InAppPurchasesManager())
}
