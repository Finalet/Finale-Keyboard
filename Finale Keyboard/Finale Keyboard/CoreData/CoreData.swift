//
//  CoreData.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 1/9/24.
//

import Foundation
import CoreData

class CoreData {
    static let shared = CoreData()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let storeURL = URL.storeURL(for: "group.finale-keyboard-cache", databaseName: "DataModel")
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        let container = NSPersistentContainer(name: "DataModel")
        container.persistentStoreDescriptions = [storeDescription]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func SaveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Saved context")
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func TestCoreData() {
        print("Initializing dictionary")
        let startTime = Date().timeIntervalSinceReferenceDate
        
//        let nGram = Ngram(context: context)
//        nGram.ngram = "q"
//
//        let charProb = CharacterProbability(context: context)
//        charProb.character = "u"
//        charProb.probability = 0.93
//        charProb.ngram = nGram
//
//        let dictionary = NgramDictionary(context: context)
//        dictionary.addToSingleGram(nGram)
//
//        CoreData.shared.SaveContext()
        
        let fetch1 = Ngram.fetchRequest()
        fetch1.predicate = NSPredicate(format: "ngram == %@", "q")
        do {
            let result = try context.fetch(fetch1).first
            guard let result = result else { return }
            let probabilities: [CharacterProbability] = result.characterProbabilities?.array as! [CharacterProbability]
            print(probabilities.first?.character)
            print(probabilities.first?.probability)

            let endTime = Date().timeIntervalSinceReferenceDate
            print("Operation took \(endTime - startTime)s")
        } catch let error as NSError {
            print(error)
        }
    }
}


public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}
