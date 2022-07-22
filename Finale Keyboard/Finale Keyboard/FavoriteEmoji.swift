//
//  FavoriteEmoji.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 2/7/22.
//

import SwiftUI

struct FavoriteEmoji: View {
    @Binding var favoriteEmoji: [String]
    @FocusState private var focusCell: Int?
        
    var body: some View {
        List {
            Section(footer: Text(Localization.FavoriteEmojiScreen.footer)) {
                HStack(alignment: .center, spacing: 5) {
                    ForEach (0..<8) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextFieldStyle())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                            .onChange(of: favoriteEmoji[i]) { value in
                                EndEditCell(index: i)
                            }
                            .focused($focusCell, equals: i)
                    }
                }.listRowSeparator(.hidden)
                HStack(alignment: .center, spacing: 5) {
                    ForEach (8..<16) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextFieldStyle())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                            .onChange(of: favoriteEmoji[i]) { value in
                                EndEditCell(index: i)
                            }
                            .focused($focusCell, equals: i)
                    }
                }.listRowSeparator(.hidden)
                HStack(alignment: .center, spacing: 5) {
                    ForEach (16..<24) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextFieldStyle())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                            .onChange(of: favoriteEmoji[i]) { value in
                                EndEditCell(index: i)
                            }
                            .focused($focusCell, equals: i)
                    }
                }.listRowSeparator(.hidden)
                HStack(alignment: .center, spacing: 5) {
                    ForEach (24..<32) { i in
                        TextField("", text: $favoriteEmoji[i])
                            .textFieldStyle(EmojiTextFieldStyle())
                            .onTapGesture {
                                favoriteEmoji[i] = ""
                            }
                            .onChange(of: favoriteEmoji[i]) { value in
                                EndEditCell(index: i)
                            }
                            .focused($focusCell, equals: i)
                    }
                }.listRowSeparator(.hidden)
            }
        }
        .navigationTitle(Localization.FavoriteEmojiScreen.title)
        .onTapGesture() {
            UIApplication.shared.endEditing()
            focusCell = -1
            SaveArray()
        }
        .onDisappear() {
            SaveArray()
        }
    }
    
    func SaveArray () {
        let userDefaults = UserDefaults(suiteName: "group.finale-keyboard-cache")
        userDefaults?.setValue(favoriteEmoji, forKey: "FINALE_DEV_APP_favorite_emoji")
    }
    func EndEditCell (index: Int) {
        if favoriteEmoji[index].count > 1 {
            if favoriteEmoji[index].last! == " " {
                favoriteEmoji[index].removeLast()
            }
            if favoriteEmoji[index].last!.isEmoji {
                favoriteEmoji[index] = String(favoriteEmoji[index].last!)
            } else {
                favoriteEmoji[index] = String(favoriteEmoji[index].first!)
            }
        }
        if favoriteEmoji[index].count > 0 {
            if !Character(favoriteEmoji[index]).isEmoji {
                favoriteEmoji[index] = ""
            } else {
                focusCell = index + 1
                if focusCell ?? 30 >= 30 {
                    focusCell == -1
                    UIApplication.shared.endEditing()
                }
            }
        }
        SaveArray()
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

struct EmojiTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Font.system(size: 30, design: .default))
            .multilineTextAlignment(.center)
            .background(Color(uiColor: .systemGray5))
            .cornerRadius(6)
            .accentColor(.gray)
    }
}
