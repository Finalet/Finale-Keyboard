//
//  FinaleKeyboard+DynamicTouchZones.swift
//  Keyboard
//
//  Created by Grant Oganyan on 1/7/24.
//

import Foundation
import UIKit

extension FinaleKeyboard {
    
    func LoadNgrams () {
        for n in 1...4 {
            let data = (try? Data(contentsOf: Bundle.main.url(forResource: "english-30000-n\(n)-probabilities", withExtension: "json")!))!
            let entries = try! JSONDecoder().decode([String:[CharacterProbability]].self, from: data)
            ngrams.append(entries)
        }
    }
    
    func ProcessDynamicTapZones () {
        ResetDynamicTapZones()
        
        if let lastNSubstring = getStringBeforeCursor(length: 4), let lastSubstring = lastNSubstring.split(separator: " ").last {
            let lastString = String(lastSubstring).lowercased()
            print(lastString)
            if let arrayOfProbabilities = ngrams[lastString.count - 1][lastString] {
                print(arrayOfProbabilities)
                let slice = Array(arrayOfProbabilities.prefix(maxDynamicTapZonePredictions))
                
                for slice in slice.reversed() {
                    ScaleCharacterKey(key: slice.character, by: min(slice.probability, maxDynamicTapZoneScale))
                }
            }
        }
    }
    
    func ResetDynamicTapZones () {
        characterButtons.forEach {
            $0.value.ScaleTouchZone(by: 0)
        }
    }
    
    func ScaleCharacterKey(key: String, by: CGFloat) {
        if let button = characterButtons[key] {
            button.ScaleTouchZone(by: by)
            button.touchZone.backgroundColor = .systemBlue.withAlphaComponent(by / CGFloat(maxDynamicTapZoneScale * 1.1))
            keysView.bringSubviewToFront(button)
        }
    }
    
}

struct CharacterProbability: Codable {
    let character: String
    let probability: CGFloat
}
