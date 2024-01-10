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
    
    func LoadNgramsToCoreData(onProgressChange: @escaping (_ status: String, _ isDone: Bool) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            onProgressChange("Started loading n-grams", false)
            let startTime = Date().timeIntervalSinceReferenceDate
            
            var eng: [Dictionary<String, [CharacterProbabilityJSON]>] = []
            var rus: [Dictionary<String, [CharacterProbabilityJSON]>] = []

            for n in 1...5 {
                onProgressChange("Loading \(n)-gram dictionary...", false)
                
                let dataEn = (try? Data(contentsOf: Bundle.main.url(forResource: "english-30000-n\(n)-probabilities", withExtension: "json")!))!
                let entriesEn = try! JSONDecoder().decode([String:[CharacterProbabilityJSON]].self, from: dataEn)
                eng.append(entriesEn)

                let dataRu = (try? Data(contentsOf: Bundle.main.url(forResource: "russian-50000-n\(n)-probabilities", withExtension: "json")!))!
                let entriesRu = try! JSONDecoder().decode([String:[CharacterProbabilityJSON]].self, from: dataRu)
                rus.append(entriesRu)
            }
            
            DispatchQueue.main.async {
                let context = CoreData.shared.persistentContainer.newBackgroundContext()
                context.automaticallyMergesChangesFromParent = true
                context.perform {
                    let ngramDictionary = NgramDictionary(context: context)
                    
                    for n in 0..<eng.count {
                        onProgressChange("Writing \(n)-gram to database...", false)
                        eng[n].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                            ngramDictionary.addToEng(self.createNgram(ngram: key, probabilities: value, context: context))
                        }
                        rus[n].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                            ngramDictionary.addToRu(self.createNgram(ngram: key, probabilities: value, context: context))
                        }
                    }
                    
                    do {
                        onProgressChange("Saving the database...", false)
                        try context.save()
                    } catch let error as NSError {
                        print("Error saving context")
                        print(error)
                    }
                    
                    let endTime = Date().timeIntervalSinceReferenceDate
                    onProgressChange("Done. Operation took \(endTime - startTime) seconds.", true)
                }
            }
        }
    }
    
    func createNgram(ngram: String, probabilities: [CharacterProbabilityJSON], context: NSManagedObjectContext) -> Ngram {
        let nGram = Ngram(context: context)
        nGram.ngram = ngram
        
        for charProb in probabilities {
            let charProbability = CharacterProbability(context: context)
            charProbability.character = charProb.character
            charProbability.probability = Float(charProb.probability)
            
            nGram.addToCharacterProbabilities(charProbability)
        }
        return nGram
    }
    
    func DeleteAllNgrams (onProgressChange: @escaping (_ status: String, _ isDone: Bool) -> ()) {
        onProgressChange("Deleting all n-grams...", false)
        let context = CoreData.shared.persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.perform {
            let fetch = NgramDictionary.fetchRequest()
            fetch.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetch)
                for result in results {
                    context.delete(result)
                }
                try context.save()
                onProgressChange("Done.", true)
            } catch let error {
                print("Failed to delete all data.", error)
            }
        }
    }
    
    func getCharacterProbabilities(_ str: String) -> [CharacterProbability]? {
        let fetch = Ngram.fetchRequest()
        fetch.predicate = NSPredicate(format: "ngram = %@", str)
        do {
            let result = try CoreData.shared.context.fetch(fetch).first
            return result?.characterProbabilities?.array as? [CharacterProbability]
        } catch let error as NSError {
            print("[\(str)] Failed to fetch ngram.")
            print(error)
            return nil
        }
    }
    
    var totalNgramsLoaded: Int {
        let fetch = Ngram.fetchRequest()
        do {
            let results = try CoreData.shared.context.fetch(fetch)
            return results.count
        } catch let error as NSError {
            print(error)
            return 0
        }
    }
    
    struct CharacterProbabilityJSON: Codable {
        let character: String
        let probability: CGFloat
    }
}
