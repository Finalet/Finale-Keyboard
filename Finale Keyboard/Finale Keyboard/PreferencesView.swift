//
//  PreferencesView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 3/13/22.
//

import Foundation
import SwiftUI
import Charts

struct PreferencesView: View {
    @State var autocorrectWords = true
    @State var autocorrectGrammar = true
    @State var autocapitalizeWords = true
    @State var isTypingHapticEnabled = false
    @State var isGesturesHapticEnabled = false
    
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
                ListNavigationLink(destination: DynamicTouchZones()) {
                    Text("Dynamic Touch Zones")
                }
                .frame(height: 30)
                ListNavigationLink(destination: PreferencesPunctuationView()) {
                    Text(Localize.Punctuation.pageTitle)
                }
                .frame(height: 30)
                ListNavigationLink(destination: AdvancedView()) {
                    Text(Localize.Advanced.pageTitle)
                }
                .frame(height: 30)
            }
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
        userDefaults?.setValue(isTypingHapticEnabled, forKey: "FINALE_DEV_APP_isTypingHapticEnabled")
        userDefaults?.setValue(isGesturesHapticEnabled, forKey: "FINALE_DEV_APP_isGesturesHapticEnabled")
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        autocorrectWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectWords") as? Bool ?? true
        autocorrectGrammar = userDefaults?.value(forKey: "FINALE_DEV_APP_autocorrectGrammar") as? Bool ?? true
        autocapitalizeWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autocapitalizeWords") as? Bool ?? true
        isTypingHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isTypingHapticEnabled") as? Bool ?? false
        isGesturesHapticEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isGesturesHapticEnabled") as? Bool ?? true
    }
}


struct PreferencesPunctuationView: View {
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

struct DynamicTouchZones: View {
    
    let suiteName = "group.finale-keyboard-cache"
    
    @State var testText = ""
    
    @State var isDynamicTapZonesEnabled: Bool = false
    @State var showTouchZones: Bool = false
    @State var maxTouchZoneScale: Float = 0.4
    @State var dynamicTapZoneProbabilityMultiplier: Float = 1.2
    @State var dynamicKeyHighlighting: Bool = false
    
    @State var loadingStatus: String? = nil
    @State var isDictionaryLoaded: Bool = false
    
    @FocusState private var shouldShowKeyboard: Bool
    
    typealias Localize = Localization.HomeScreen
    
    var body: some View {
        List {
            Section (footer: Text("When enabled, Finale Keyboard will try to predict what key you will tap next and slightly increase its tap zone.")) {
                Toggle("Enable", isOn: $isDynamicTapZonesEnabled.animation())
                    .onChange(of: isDynamicTapZonesEnabled) { value in
                        OnChange()
                    }
                if isDynamicTapZonesEnabled {
                    Toggle("Highlight keys", isOn: $dynamicKeyHighlighting.animation())
                        .onChange(of: dynamicKeyHighlighting) { value in
                            if value && showTouchZones { withAnimation { showTouchZones = false } }
                            OnChange()
                        }
                }
            }
            if isDynamicTapZonesEnabled {
                Section (footer: Text(loadingStatus == nil ? !isDictionaryLoaded ? "Dictionary is required for dynamic touch zones to work." : "" : "\(!isDictionaryLoaded ? "Loading" : "Deleting") can take up to a minute. Do not leave this page until it is done.")) {
                    HStack{
                        if loadingStatus == nil {
                            Image(systemName: isDictionaryLoaded ? "checkmark" : "exclamationmark.triangle")
                                .foregroundColor(isDictionaryLoaded ? .green : .red)
                        } else {
                            ProgressView()
                                .tint(.gray)
                                .padding(.trailing, 4)
                        }
                        Text(loadingStatus ?? "Dictionary\(isDictionaryLoaded ? " " : " not ")loaded")
                            .foregroundColor(loadingStatus != nil ? .gray : isDictionaryLoaded ? .green : .red)
                        Spacer()
                        Button(action: {
                            if !isDictionaryLoaded {
                                Ngrams.shared.LoadNgramsToCoreData() { status, isDone in
                                    loadingStatus = isDone ? nil : status
                                    if isDone { isDictionaryLoaded = Ngrams.shared.totalNgramsLoaded > 0 }
                                }
                            } else {
                                Ngrams.shared.DeleteAllNgrams() { status, isDone in
                                    loadingStatus = isDone ? nil : status
                                    if isDone { isDictionaryLoaded = Ngrams.shared.totalNgramsLoaded > 0 }
                                }
                            }
                        }, label: {
                            Text(loadingStatus == nil ? (!isDictionaryLoaded ? "Load" : "Delete") : "")
                        })
                        .disabled(loadingStatus != nil)
                    }
                }
                Section(header: Text("Advanced")) {
                    Toggle("Show touch zones", isOn: $showTouchZones.animation())
                        .onChange(of: showTouchZones) { value in
                            if value && dynamicKeyHighlighting { withAnimation { dynamicKeyHighlighting = false } }
                            OnChange()
                        }
                    TextField(Localize.inputFieldPlaceholder, text: $testText)
                        .focused($shouldShowKeyboard)
                }
                if #available(iOS 16.0, *) {
                    ScaleGraph(maxScale: $maxTouchZoneScale, multiplier: $dynamicTapZoneProbabilityMultiplier)
                }
                Section (footer: Text("Default: 140%")) {
                    TextRow(label: "Maximum key scale", value: "\(100 + Int(maxTouchZoneScale*100))%")
                    Slider(value: $maxTouchZoneScale, in: 0.05...1.0, step: 0.05) { _ in
                        OnChange()
                    }
                }
                Section (footer: Text("Default: 1.2")) {
                    TextRow(label: "Scale multiplier", value: "\(round(dynamicTapZoneProbabilityMultiplier*10)/10)")
                    Slider(value: $dynamicTapZoneProbabilityMultiplier, in: 1.0...3.0, step: 0.1) { _ in
                        OnChange()
                    }
                }
            }
        }
        .navigationTitle("Dynamic Touch Zones")
        .onAppear {
            Load()
        }
    }
    
    @ViewBuilder
    func TextRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
    }
    
    func OnChange () {
        shouldShowKeyboard = false
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(isDynamicTapZonesEnabled, forKey: "FINALE_DEV_APP_isDynamicTapZonesEnabled")
        userDefaults?.setValue(showTouchZones, forKey: "FINALE_DEV_APP_showTouchZones")
        userDefaults?.setValue(maxTouchZoneScale, forKey: "FINALE_DEV_APP_maxTouchZoneScale")
        userDefaults?.setValue(dynamicTapZoneProbabilityMultiplier, forKey: "FINALE_DEV_APP_dynamicTapZoneProbabilityMultiplier")
        userDefaults?.setValue(dynamicKeyHighlighting, forKey: "FINALE_DEV_APP_dynamicKeyHighlighting")
    }
    
    func Load () {
        isDictionaryLoaded = Ngrams.shared.totalNgramsLoaded > 0
        
        let userDefaults = UserDefaults(suiteName: suiteName)
        isDynamicTapZonesEnabled = userDefaults?.value(forKey: "FINALE_DEV_APP_isDynamicTapZonesEnabled") as? Bool ?? false
        showTouchZones = userDefaults?.value(forKey: "FINALE_DEV_APP_showTouchZones") as? Bool ?? false
        maxTouchZoneScale = userDefaults?.value(forKey: "FINALE_DEV_APP_maxTouchZoneScale") as? Float ?? 0.4
        dynamicTapZoneProbabilityMultiplier = userDefaults?.value(forKey: "FINALE_DEV_APP_dynamicTapZoneProbabilityMultiplier") as? Float ?? 1.2
        dynamicKeyHighlighting = userDefaults?.value(forKey: "FINALE_DEV_APP_dynamicKeyHighlighting") as? Bool ?? false
    }
}

@available(iOS 16.0, *)
struct ScaleGraph: View {
    
    @Binding var maxScale: Float
    @Binding var multiplier: Float
    
    var interceptX: Float {
        return 1 / multiplier
    }
    
    var second: (Int, Int) {
        return (Int(interceptX*100), Int(maxScale*100+100))
    }
    var last: (Int, Int) {
        return (Int(100), Int(maxScale*100+100))
    }
    
    var yAxisLabels: [Int] {
        return [Int(100), Int(last.1), Int(200)]
    }
    var xAxisLabels: [Int] {
        return [0, Int(interceptX*100), 100]
    }
    
    var body: some View {
        Chart {
            LineMark(x: .value("Probability", 0), y: .value("Scale", 100))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Probability", second.0), y: .value("Scale", second.1))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Probability", last.0), y: .value("Scale", last.1))
                .interpolationMethod(.monotone)
        }
        .listRowBackground(Color(UIColor.systemGroupedBackground))
        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .chartXAxisLabel("Key probability", alignment: .center)
        .chartYAxisLabel("Touch zone scale", position: .trailing, alignment: .center)
        .chartYAxis {
            AxisMarks(format: .percent.scale(1), values: yAxisLabels)
        }
        .chartXAxis {
            AxisMarks(format: .percent.scale(1), values: xAxisLabels)
        }
        .chartYScale(domain: [100, 200])
        .chartXScale(domain: [0, 100])
        .aspectRatio(1.7, contentMode: .fill)
    }
}
