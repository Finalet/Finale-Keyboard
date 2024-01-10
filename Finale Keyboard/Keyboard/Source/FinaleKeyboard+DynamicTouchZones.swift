//
//  FinaleKeyboard+DynamicTouchZones.swift
//  Keyboard
//
//  Created by Grant Oganyan on 1/7/24.
//

import Foundation
import UIKit

extension FinaleKeyboard {
    
    func ProcessDynamicTapZones () {
        if !FinaleKeyboard.isDynamicTapZonesEnabled { return }
        
        ResetDynamicTapZones()
        
        if let lastNSubstring = getStringBeforeCursor(length: maxNgram), let lastSubstring = lastNSubstring.split(separator: " ").last {
            let lastString = String(lastSubstring).lowercased()
            if lastString.count < minNgram { return }
            
            if let probabilities = Ngrams.shared.getCharacterProbabilities(lastString) {
                for probability in probabilities.reversed() {
                    guard let char = probability.character else { continue }
                    
                    let prob = CGFloat(probability.probability) 
                    let by = min(prob * FinaleKeyboard.maxDynamicTapZoneScale * FinaleKeyboard.dynamicTapZoneProbabilityMultiplier, FinaleKeyboard.maxDynamicTapZoneScale)
                    ScaleCharacterKey(key: char, by: by)
                }
            }
        }
    }
    
    func ResetDynamicTapZones () {
        characterButtons.forEach {
            $0.value.ScaleTouchZone(by: 0.0)
        }
    }
    
    func ScaleCharacterKey(key: String, by: CGFloat) {
        if let button = characterButtons[key] {
            button.ScaleTouchZone(by: by)
            keysView.bringSubviewToFront(button)
        }
    }
    
}
