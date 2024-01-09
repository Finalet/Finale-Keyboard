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
                    let engNgramDictionary = NgramDictionary(context: context)
                    let rusNgramDictionary = NgramDictionary(context: context)
                    
                    onProgressChange("Writing 0-gram to database...", false)
                    eng[0].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        engNgramDictionary.addToSingleGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    rus[0].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        rusNgramDictionary.addToSingleGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    
                    onProgressChange("Writing 1-gram to database...", false)
                    eng[1].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        engNgramDictionary.addToBiGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    rus[1].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        rusNgramDictionary.addToBiGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    
                    onProgressChange("Writing 2-gram to database...", false)
                    eng[2].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        engNgramDictionary.addToTriGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    rus[2].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        rusNgramDictionary.addToTriGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    
                    onProgressChange("Writing 3-gram to database...", false)
                    eng[3].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        engNgramDictionary.addToQuadGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    rus[3].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        rusNgramDictionary.addToQuadGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    
                    onProgressChange("Writing 4-gram to database...", false)
                    eng[4].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        engNgramDictionary.addToPentaGram(self.createNgram(ngram: key, probabilities: value, context: context))
                    }
                    rus[4].forEach { (key: String, value: [CharacterProbabilityJSON]) in
                        rusNgramDictionary.addToPentaGram(self.createNgram(ngram: key, probabilities: value, context: context))
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
        let n = str.count
        if n > 5 { return nil }
       
        let fetch = Ngram.fetchRequest()
        fetch.predicate = NSPredicate(format: "ngram = %@", str)
        do {
            let results = try CoreData.shared.context.fetch(fetch).first
            return results?.characterProbabilities?.array as? [CharacterProbability]
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
