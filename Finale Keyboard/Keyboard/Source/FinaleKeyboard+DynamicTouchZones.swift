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
        let startTime = Date()
        
        ngramsEnglish = [[:]]
        ngramsRussian = [[:]]
        
        DispatchQueue.global(qos: .default).async {
            var eng: [Dictionary<String, [CharacterProbability]>] = []
            var rus: [Dictionary<String, [CharacterProbability]>] = []

            for n in self.minNgram...self.maxNgram {
                let dataEn = (try? Data(contentsOf: Bundle.main.url(forResource: "english-30000-n\(n)-probabilities", withExtension: "json")!))!
                let entriesEn = try! JSONDecoder().decode([String:[CharacterProbability]].self, from: dataEn)
                eng.append(entriesEn)

                let dataRu = (try? Data(contentsOf: Bundle.main.url(forResource: "russian-50000-n\(n)-probabilities", withExtension: "json")!))!
                let entriesRu = try! JSONDecoder().decode([String:[CharacterProbability]].self, from: dataRu)
                rus.append(entriesRu)
            }

            self.ngramsEnglish = eng
            self.ngramsRussian = rus

            let endTime = Date()
            
            print("Loading ngrams took \(endTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate) seconds." )
        }
    }
    
    func ProcessDynamicTapZones () {
        ResetDynamicTapZones()
        
        if let lastNSubstring = getStringBeforeCursor(length: maxNgram), let lastSubstring = lastNSubstring.split(separator: " ").last {
            let lastString = String(lastSubstring).lowercased()
            if lastString.count < minNgram { return }
            
            if let arrayOfProbabilities = (FinaleKeyboard.currentLocale == .en_US ? ngramsEnglish[lastString.count - minNgram] : ngramsRussian[lastString.count - minNgram])[lastString] {
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
