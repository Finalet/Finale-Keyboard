//
//  FavoriteEmoji.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 2/7/22.
//

import SwiftUI

struct FavoriteEmoji: View {
    @Binding var favoriteEmoji: [String]
        
    var body: some View {
        List {
            Section(footer: Text("Pick emoji that are going to show up first in the emoji keyboard.")) {
                HStack(alignment: .center, spacing: 5) {
                    ForEach (0..<8) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextField())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                    }
                }.listRowSeparator(.hidden)
                HStack(alignment: .center, spacing: 5) {
                    ForEach (8..<16) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextField())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                    }
                }.listRowSeparator(.hidden)
                HStack(alignment: .center, spacing: 5) {
                    ForEach (16..<24) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextField())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                    }
                }.listRowSeparator(.hidden)
                HStack(alignment: .center, spacing: 5) {
                    ForEach (24..<32) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextField())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                    }
                }.listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Favorite Emoji")
        .onTapGesture() {
            UIApplication.shared.endEditing()
            SaveArray()
            for i in 0..<favoriteEmoji.count {
                if favoriteEmoji[i].count > 1 {
                    favoriteEmoji[i] = String(favoriteEmoji[i].last!)
                }
                if (favoriteEmoji[i].count == 1) {
                    if !Character(favoriteEmoji[i]).isEmoji {
                        favoriteEmoji[i] = ""
                    }
                }
            }
        }
        .onDisappear() {
            SaveArray()
        }
    }
    
    func SaveArray () {
        let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        userDefaults?.setValue(favoriteEmoji, forKey: "FINALE_DEV_APP_favorite_emoji")
    }
    
}

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EmojiTextField: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Font.system(size: 32, design: .default))
            .multilineTextAlignment(.center)
            .background(Color(uiColor: .systemGray5))
            .cornerRadius(6)
            .accentColor(.gray)
    }
}