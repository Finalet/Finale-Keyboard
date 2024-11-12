//
//  TutorialView.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 3/9/22.
//

import Foundation
import SwiftUI

struct DictionaryListView: View {
    @State var userDictionary = [String]()
    @State private var searchText = ""
    
    @State var autoLearnWords = true
    let tintColor = Color(red: 0.33, green: 0.51, blue: 0.85)
    
    @State private var isImportingDictionary: Bool = false
    @State private var dictionaryFileURL: ShareFile?
    @State private var isSharingDictionary: Bool = false
    
    @State private var isClearingDictionary: Bool = false
    
    let suiteName = "group.finale-keyboard-cache"
    
    var body: some View {
        List {
            Section (footer: Text(footerText)) {
                Toggle(Localization.DictionaryScreen.learnWordsAutomatically, isOn: $autoLearnWords)
                    .toggleStyle(SwitchToggleStyle(tint: tintColor))
                    .onChange(of: autoLearnWords) { value in
                        OnChange()
                    }
            }
            Section(footer: Text(Localization.DictionaryScreen.footer)) {
                ForEach(searchResults, id: \.self) { word in
                    Text(word)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle(Localization.DictionaryScreen.title)
        .onAppear {
            Load()
        }
        .searchable(text: $searchText)
        .toolbar {
             ToolbarItem(placement: .navigationBarTrailing) {
                 Menu(content: {
                     Button(Localization.Actions.export, systemImage: "square.and.arrow.up") {
                         ExportJSON()
                     }
                     Button(Localization.Actions.Import, systemImage: "square.and.arrow.down") {
                         isImportingDictionary = true
                     }
                     Divider()
                     Button(Localization.Actions.clear, systemImage: "trash", role: .destructive) {
                         isClearingDictionary = true
                     }
                 }, label: {
                     Image(systemName: "ellipsis")
                 })
              }
          }
        .sheet(item: $dictionaryFileURL) { dictionaryFileURL in
            ActivityViewController(activityItems: [dictionaryFileURL.fileURL])
        }
        .fileImporter(isPresented: $isImportingDictionary, allowedContentTypes: [.json], onCompletion: { results in
            switch results {
            case .success(let fileURL):
                let gotAccess = fileURL.startAccessingSecurityScopedResource()
                if !gotAccess { return }
                ImportJSON(fileURL: fileURL)
                fileURL.stopAccessingSecurityScopedResource()
            case .failure(let error):
                print(error)
            }
        })
        .alert(isPresented: $isClearingDictionary) {
            Alert(title: Text(Localization.DictionaryScreen.clearDictionaryConfirmation), primaryButton: .destructive(Text(Localization.Actions.clear), action: ClearDictionary), secondaryButton: .cancel())
        }
    }
    
    func OnChange () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(autoLearnWords, forKey: "FINALE_DEV_APP_autoLearnWords")
    }
    
    var footerText: String {
        return autoLearnWords ? Localization.DictionaryScreen.learnWordsAutomaticallyIsOn : Localization.DictionaryScreen.learnWordsAutomaticallyIsOff
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return userDictionary.sorted()
        } else {
            return userDictionary.sorted().filter { $0.contains(searchText.lowercased()) }
        }
    }
    
    func delete(at offsets: IndexSet) {
        userDictionary.remove(at: userDictionary.firstIndex(of: searchResults[offsets.first!])!)
        SaveUserDictionary()
    }
    
    func Load () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDictionary = userDefaults?.value(forKey: "FINALE_DEV_APP_userDictionary") as? [String] ?? [String]()
        autoLearnWords = userDefaults?.value(forKey: "FINALE_DEV_APP_autoLearnWords") as? Bool ?? true
    }
    
    func SaveUserDictionary () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.setValue(userDictionary, forKey: "FINALE_DEV_APP_userDictionary")
    }
    func ExportJSON () {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let data = try? jsonEncoder.encode(userDictionary)
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("Finale Keyboard Dictionary.json")
        try? data?.write(to: fileURL)
        
        dictionaryFileURL = ShareFile(fileURL: fileURL)
    }
    func ImportJSON (fileURL: URL) {
        let data = try? Data(contentsOf: fileURL)
        guard let data else { return }
        
        let jsonDecoder = JSONDecoder()
        let importedDictionary = try? jsonDecoder.decode([String].self, from: data)
        guard var importedDictionary else { return }
        
        // clean words
        importedDictionary = importedDictionary.filter({ word in
            return !word.isEmpty && !userDictionary.contains(word)
        })
        
        // remove duplicates
        importedDictionary = Array(Set(importedDictionary))
        
        userDictionary.append(contentsOf: importedDictionary)
        SaveUserDictionary()
    }
    func ClearDictionary () {
        userDictionary.removeAll()
        SaveUserDictionary()
    }
}

struct ShareFile: Identifiable {
    let id = UUID()
    let fileURL: URL
}
