//
//  Ngrams.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 1/9/24.
//

import Foundation
import CoreData

class Ngrams {
    static let shared = Ngrams()
    
    func LoadNgramsToCoreData(locale: Locale, onProgressChange: @escaping (_ status: String, _ isDone: Bool) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async { onProgressChange(Ngrams.Localize.startedLoading, false) }
            
            var dict: [Dictionary<String, [CharacterProbability]>] = []
            
            for n in 1...5 {
                DispatchQueue.main.async { onProgressChange(String(format: Ngrams.Localize.loadingNDictionary, n), false) }
                
                let jsonFileName = self.getNgramJsonFileName(locale, n)
                
                guard let file = Bundle.main.url(forResource: jsonFileName, withExtension: "json"), let data = try? Data(contentsOf: file) else { continue }
                guard let entries = try? JSONDecoder().decode([String:[CharacterProbability]].self, from: data) else { continue }
                
                dict.append(entries)
            }
            
            DispatchQueue.main.async {
                let backgroundContext = CoreData.shared.persistentContainer.newBackgroundContext()
                backgroundContext.automaticallyMergesChangesFromParent = true
                
                backgroundContext.perform {
                    for n in 0..<dict.count {
                        DispatchQueue.main.async { onProgressChange(String(format: Ngrams.Localize.writingNToDatabase, n + 1), false) }
                        
                        dict[n].forEach { (ngram: String, probabilities: [CharacterProbability]) in
                            self.createNgramObject(locale: locale, ngram: ngram, probabilities: probabilities, context: backgroundContext)
                        }
                        
                        try? backgroundContext.save()
                    }
                    
                    DispatchQueue.main.async {  onProgressChange("", true) }
                }
            }
        }
    }
    
    func createNgramObject(locale: Locale, ngram: String, probabilities: [CharacterProbability], context: NSManagedObjectContext) {
        guard let probabilitiesData = try? JSONEncoder().encode(probabilities) else { return }
        
        let ngramObject = Ngram(context: context)
        ngramObject.locale = locale.languageCode
        ngramObject.ngram = ngram
        ngramObject.probabilities = probabilitiesData
    }
    
    func DeleteNgramsFromCoreData(forLocale: Locale, onProgressChange: @escaping (_ status: String, _ isDone: Bool) -> ()) {
        DispatchQueue.main.async { onProgressChange(Ngrams.Localize.deletingDictionary, false) }
        
        let backgroundContext = CoreData.shared.persistentContainer.newBackgroundContext()
        
        backgroundContext.perform {
            let fetch = Ngram.fetchRequest()
            fetch.predicate = NSPredicate(format: "locale == %@", forLocale.languageCode)
            
            if let results = try? backgroundContext.fetch(fetch) {
                for object in results {
                    backgroundContext.delete(object)
                }
            }
            
            try? backgroundContext.save()
            
            DispatchQueue.main.async { onProgressChange("", true) }
        }
    }
    
    func getCharacterProbabilities(_ ngram: String, locale: Locale, callback: @escaping ([CharacterProbability]?) -> ()) {
        let backgroundContext = CoreData.shared.persistentContainer.newBackgroundContext()
        backgroundContext.perform {
            let fetch = Ngram.fetchRequest()
            fetch.predicate = NSPredicate(format: "locale == %@ AND ngram == %@", locale.languageCode, ngram)
            fetch.fetchLimit = 1
            
            let result = try? backgroundContext.fetch(fetch).first
            
            guard let binaryData = result?.probabilities, let decodedProbabilities = try? JSONDecoder().decode([CharacterProbability].self, from: binaryData) else {
                DispatchQueue.main.async { callback(nil) }
                return
            }
            
            DispatchQueue.main.async { callback(decodedProbabilities) }
            return
        }
    }
    
    func isLocaleLoadedIntoCoreData (_ locale: Locale) -> Bool {
        let fetch = Ngram.fetchRequest()
        fetch.predicate = NSPredicate(format: "locale == %@", locale.languageCode)
        fetch.fetchLimit = 1
        
        let result = try? CoreData.shared.context.fetch(fetch)
        
        return result?.count ?? 0 > 0
    }
    
    func getNgramJsonFileName (_ forLocale: Locale, _ n: Int) -> String {
        let fileName: String
        switch forLocale {
        case .en_US: fileName = "english-30000-n%D-probabilities"
        case .ru_RU: fileName = "russian-50000-n%D-probabilities"
        case .es_ES: fileName = "spanish-30000-n%D-probabilities"
        }
        return String(format: fileName, n)
    }
    
    struct CharacterProbability: Codable {
        let character: String
        let probability: CGFloat
    }
    
    struct Localize {
        static var startedLoading = NSLocalizedString("ngram_loading_status_started", value: "Started loading n-grams", comment: "")
        static var loadingNDictionary = NSLocalizedString("ngram_loading_n_dictionary", value: "Loading %D-gram dictionary...", comment: "")
        static var writingNToDatabase = NSLocalizedString("ngram_writing_n_to_database", value: "Writing %D-gram to database...", comment: "")
        static var deletingDictionary = NSLocalizedString("ngram_deleting_ngrams", value: "Deleting dictionary...", comment: "")
    }
}
