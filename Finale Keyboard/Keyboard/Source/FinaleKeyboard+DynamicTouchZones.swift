//
//  FinaleKeyboard+DynamicTouchZones.swift
//  Keyboard
//
//  Created by Grant Oganyan on 1/7/24.
//

import Foundation
import UIKit

extension FinaleKeyboard {
    
    func ProcessDynamicTouchZones () {
        if !FinaleKeyboard.isDynamicTapZonesEnabled { return }
        
        ResetDynamicTouchZones()
        
        if let lastNSubstring = getStringBeforeCursor(length: maxNgram), let lastSubstring = lastNSubstring.split(separator: " ").last {
            let lastString = String(lastSubstring).lowercased()
            if lastString.count < minNgram { return }
            
            Ngrams.shared.getCharacterProbabilities(lastString) { probabilities in
                guard let probabilities = probabilities else { return }
                
                for probability in probabilities.reversed() {
                    guard let char = probability.character else { continue }
                    
                    let prob = CGFloat(probability.probability) 
                    let by = min(prob * FinaleKeyboard.maxTouchZoneScale * FinaleKeyboard.dynamicTapZoneProbabilityMultiplier, FinaleKeyboard.maxTouchZoneScale)
                    self.ScaleCharacterKey(key: char, by: by)
                }
            }
        }
    }
    
    func ResetDynamicTouchZones () {
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
