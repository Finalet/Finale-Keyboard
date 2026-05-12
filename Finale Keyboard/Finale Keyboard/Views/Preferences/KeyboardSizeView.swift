//
//  KeyboardSizeView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 5/12/26.
//

import SwiftUI
import Foundation

struct KeyboardSizeView: View {
    
    @State var sliderValue: CGFloat = 0
    @UserDefaultState("FINALE_DEV_APP_keyboardHeightMultiplier", 1.0) var keyboardHeightMultiplier: CGFloat
    
    typealias Localize = Localization.PreferencesScreen.KeyboardSize
    
    let min: CGFloat = 0.8
    let max: CGFloat = 1.2
    let nSteps: Int = 5
    
    var stepSize: CGFloat {
        return ((max - min) / CGFloat(nSteps)).roundTo(1)
    }
    
    var steps: [CGFloat] {
        var array: [CGFloat] = []
        for i in 0...(nSteps - 1) {
            array.append((min + (CGFloat(i) * stepSize)).roundTo(1))
        }
        return array
    }
    
    var body: some View {
        ZStack {
            List {
                Section {
                    VStack (alignment: .leading, spacing: 16) {
                        Slider(value: $sliderValue, in: 0...CGFloat(nSteps - 1), step: 1, label: {})
                        HStack {
                            ForEach(steps, id: \.self) { step in
                                HStack {
                                    Text(labelForStep(step))
                                        .font(.subheadline)
                                        .foregroundColor(keyboardHeightMultiplier == step ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, -16)
                    }
                }
                .onChange(of: sliderValue) { _, newValue in
                    let intValue = Int(newValue)
                    guard steps.indices.contains(intValue) else { return }
                    
                    withAnimation (.spring(duration: 0.5, bounce: 0.2)) {
                        keyboardHeightMultiplier = steps[intValue]
                    }
                }
            }
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Keyboard(heightMultiplier: keyboardHeightMultiplier, bottomSafeArea: geometry.safeAreaInsets.bottom)
                }
                .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
            }
        }
        .onAppear {
            let index: Int = steps.firstIndex(of: keyboardHeightMultiplier) ?? Int(floor(Float(nSteps) / 2.0))
            sliderValue = CGFloat(index)
        }
        .navigationTitle(Localize.pageTitle)
    }
     
    func labelForStep(_ step: CGFloat) -> String {
        let names = [Localize.tiny, Localize.small, Localize.normal, Localize.large, Localize.huge]
        if let index = steps.firstIndex(of: step), names.indices.contains(index) {
            return names[index]
        }
        return Localization.Misc.other
    }
    
    struct Keyboard: View {
        let heightMultiplier: CGFloat
        let bottomSafeArea: CGFloat?
        
        @UserDefaultState("FINALE_DEV_APP_isSpacebarEnabled", false) var isSpacebarEnabled
        var visualRowHeight: CGFloat { return (UIScreen.main.bounds.width < UIScreen.main.bounds.height ? 60 : 40) * (isSpacebarEnabled ? 0.9 : 1) * heightMultiplier }
        var rowsNumber: CGFloat { return isSpacebarEnabled ? 4 : 3 }
        
        init(heightMultiplier: CGFloat, bottomSafeArea: CGFloat? = nil) {
            self.heightMultiplier = heightMultiplier
            self.bottomSafeArea = bottomSafeArea
        }
        
        var body: some View {
            RoundedRectangle(cornerRadius: 20)
                .modifier(LiquidGlassBackgroundModifier(cornerRaduis: 20))
                .frame(height: rowsNumber * visualRowHeight + (bottomSafeArea ?? 0) * 2 + 4)
                .shadow(color: Color.black.opacity(0.2), radius: 4)
                .overlay(alignment: .bottom) {
                    VStack (spacing: 0) {
                        KeyboardRow(nKeys: 10)
                        KeyboardRow(nKeys: 9)
                            .background(Color.primary.opacity(0.1))
                        KeyboardRow(nKeys: 7)
                        if isSpacebarEnabled {
                            KeyboardRow(nKeys: 3)
                        }
                    }
                    .frame(height: rowsNumber * visualRowHeight)
                    .padding(.bottom, (bottomSafeArea ?? 0) * 2)
                }
        }
    }
    
    struct KeyboardRow: View {
        let globalPadding: CGFloat = 10
        let keyPadding: CGFloat = 4
        
        let nKeys: Int
        var body: some View {
            GeometryReader { geo in
                HStack (spacing: 0) {
                    ForEach(0..<nKeys, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .foregroundColor(Color.primary.opacity(0.075))
                            .frame(width: nKeys == 3 ? getSpacebarKeyWidth(in: geo.size.width, i: i) : getKeyWidth(in: geo.size.width))
                    }
                    .padding(.horizontal, keyPadding)
                    .padding(.vertical, geo.size.height * 0.15)
                }
                .padding(.horizontal, globalPadding)
            }
            .frame(maxWidth: .infinity)
        }
        
        func getKeyWidth (in width: CGFloat) -> CGFloat {
            return (width - 2.0 * globalPadding - CGFloat(nKeys) * keyPadding * 2) / CGFloat(nKeys)
        }
        
        func getSpacebarKeyWidth(in width: CGFloat, i: Int) -> CGFloat {
            let spacebarWidth = width * 0.5
            if i == 1 { return spacebarWidth }
            return (width - 2.0 * globalPadding - CGFloat(nKeys) * keyPadding * 2 - spacebarWidth) / CGFloat(2)
        }
    }
    
    struct LiquidGlassBackgroundModifier: ViewModifier {
        let cornerRaduis: CGFloat
        
        @ViewBuilder
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content.glassEffect(in: .rect(cornerRadius: cornerRaduis))
            } else {
                content.foregroundStyle(Color.primary.opacity(0.2))
            }
        }
    }
}


#Preview() {
    NavigationStack {
        KeyboardSizeView()
    }
}
