//
//  DynamicTouchZones.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI
import Charts

struct DynamicTouchZonesView: View {
    
    let suiteName = "group.finale-keyboard-cache"
    
    @State var testText = ""
    
    @UseUserDefaultState("FINALE_DEV_APP_isDynamicTapZonesEnabled", false) var isDynamicTapZonesEnabled: Bool
    @UseUserDefaultState("FINALE_DEV_APP_showTouchZones", false) var showTouchZones: Bool
    @UseUserDefaultState("FINALE_DEV_APP_maxTouchZoneScale", 0.3) var maxTouchZoneScale: Float
    @UseUserDefaultState("FINALE_DEV_APP_dynamicTapZoneProbabilityMultiplier", 1.5) var dynamicTapZoneProbabilityMultiplier: Float
    @UseUserDefaultState("FINALE_DEV_APP_dynamicKeyHighlighting", false) var dynamicKeyHighlighting: Bool
    
    @State var loadingStatus: String? = nil
    @State var isDictionaryLoaded: Bool = Ngrams.shared.isNgramDictionaryLoaded
    
    @FocusState private var shouldShowKeyboard: Bool
    
    typealias Localize = Localization.PreferencesScreen.DynamicTouchZones
    
    var body: some View {
        List {
            Section (footer: Text(Localize.explanation)) {
                Toggle(Localization.Actions.enable, isOn: $isDynamicTapZonesEnabled.animation())
                    .onChange(of: isDynamicTapZonesEnabled) { _, _ in OnChange() }
                if isDynamicTapZonesEnabled {
                    Toggle(Localize.highlightKeys, isOn: $dynamicKeyHighlighting)
                        .onChange(of: dynamicKeyHighlighting) { _, value in
                            if value && showTouchZones { withAnimation { showTouchZones = false } }
                            OnChange()
                        }
                }
            }
            if isDynamicTapZonesEnabled {
                Section (footer: Text(loadingStatus == nil ? !isDictionaryLoaded ? Localize.dictionaryRequired : "" : String(format: Localize.loadingDurationWarning, !isDictionaryLoaded ? Localization.Misc.loading : Localization.Misc.deleting))) {
                    HStack{
                        if loadingStatus == nil {
                            Image(systemName: isDictionaryLoaded ? "checkmark" : "exclamationmark.triangle")
                                .foregroundColor(isDictionaryLoaded ? .green : .red)
                        } else {
                            ProgressView()
                                .tint(.gray)
                                .padding(.trailing, 4)
                        }
                        Text(loadingStatus ?? (isDictionaryLoaded ? Localize.dictionaryLoaded : Localize.dictionaryNotLoaded))
                            .foregroundColor(loadingStatus != nil ? .gray : isDictionaryLoaded ? .green : .red)
                        Spacer()
                        Button(action: {
                            if !isDictionaryLoaded {
                                Ngrams.shared.LoadNgramsToCoreData() { status, isDone in
                                    loadingStatus = isDone ? nil : status
                                    if isDone { isDictionaryLoaded = Ngrams.shared.isNgramDictionaryLoaded }
                                }
                            } else {
                                Ngrams.shared.DeleteAllNgrams() { status, isDone in
                                    loadingStatus = isDone ? nil : status
                                    if isDone { isDictionaryLoaded = Ngrams.shared.isNgramDictionaryLoaded }
                                }
                            }
                        }, label: {
                            Text(loadingStatus == nil ? (!isDictionaryLoaded ? Localization.Actions.load : Localization.Actions.delete) : "")
                        })
                        .disabled(loadingStatus != nil)
                    }
                }
                Section(header: Text(Localization.PreferencesScreen.Advanced.pageTitle)) {
                    Toggle(Localize.showTouchZones, isOn: $showTouchZones.animation())
                        .onChange(of: showTouchZones) { _, value in
                            if value && dynamicKeyHighlighting { withAnimation { dynamicKeyHighlighting = false } }
                            OnChange()
                        }
                    TextField(Localization.HomeScreen.inputFieldPlaceholder, text: $testText)
                        .focused($shouldShowKeyboard)
                }
                if #available(iOS 16.0, *) {
                    ScaleGraph(maxScale: $maxTouchZoneScale, multiplier: $dynamicTapZoneProbabilityMultiplier)
                }
                Section (footer: Text(verbatim: "\(Localization.Misc.Default): 130%")) {
                    TextRow(label: Localize.maximumKeyScale, value: "\(100 + Int(maxTouchZoneScale*100))%")
                    Slider(value: $maxTouchZoneScale, in: 0.1...2.0, step: 0.1) { _ in OnChange() }
                }
                Section (footer: Text(verbatim: "\(Localization.Misc.Default): 1.5")) {
                    TextRow(label: Localize.scaleMultiplier, value: "\(round(dynamicTapZoneProbabilityMultiplier*10)/10)")
                    Slider(value: $dynamicTapZoneProbabilityMultiplier, in: 1.0...3.0, step: 0.1) { _ in OnChange() }
                }
            }
        }
        .navigationTitle(Localize.pageTitle)
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
        return [Int(100), Int(last.1), Int(300)]
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
        .chartXAxisLabel(Localization.PreferencesScreen.DynamicTouchZones.keyProbability, alignment: .center)
        .chartYAxisLabel(Localization.PreferencesScreen.DynamicTouchZones.touchZoneScale, position: .trailing, alignment: .center)
        .chartYAxis {
            AxisMarks(format: .percent.scale(1), values: yAxisLabels)
        }
        .chartXAxis {
            AxisMarks(format: .percent.scale(1), values: xAxisLabels)
        }
        .chartYScale(domain: [100, 300])
        .chartXScale(domain: [0, 100])
        .aspectRatio(1.7, contentMode: .fill)
    }
}
