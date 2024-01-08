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
        for n in minNgram...maxNgram {
            let dataEn = (try? Data(contentsOf: Bundle.main.url(forResource: "english-30000-n\(n)-probabilities", withExtension: "json")!))!
            let entriesEn = try! JSONDecoder().decode([String:[CharacterProbability]].self, from: dataEn)
            ngramsEnglish.append(entriesEn)
            
            let dataRu = (try? Data(contentsOf: Bundle.main.url(forResource: "russian-50000-n\(n)-probabilities", withExtension: "json")!))!
            let entriesRu = try! JSONDecoder().decode([String:[CharacterProbability]].self, from: dataRu)
            ngramsRussian.append(entriesRu)
        }
    }
    
    func ProcessDynamicTapZones () {
        ResetDynamicTapZones()
        
        if let lastNSubstring = getStringBeforeCursor(length: maxNgram), let lastSubstring = lastNSubstring.split(separator: " ").last {
            let lastString = String(lastSubstring).lowercased()
            
            if let arrayOfProbabilities = (FinaleKeyboard.currentLocale == .en_US ? ngramsEnglish[lastString.count - 1] : ngramsRussian[lastString.count - 1])[lastString] {
                let slice = Array(arrayOfProbabilities.prefix(maxDynamicTapZonePredictions))
                
                for slice in slice.reversed() {
                    ScaleCharacterKey(key: slice.character, by: min(slice.probability, maxDynamicTapZoneScale))
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

struct CharacterProbability: Codable {
    let character: String
    let probability: CGFloat
}
