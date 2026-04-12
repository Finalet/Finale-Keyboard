//
//  FavoriteEmoji.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 2/7/22.
//

import SwiftUI

struct FavoriteEmojiView: View {
    @UserDefaultState("FINALE_DEV_APP_favorite_emoji", [String](repeating: "", count: 32)) var favoriteEmoji: [String]

    @FocusState private var focusCell: Int?
        
    var body: some View {
        List {
            Section(footer: Text(Localization.FavoriteEmojiScreen.footer)) {
                VStack {
                    ForEach(0..<4) { row in
                        HStack(alignment: .center, spacing: 5) {
                            ForEach (row*8..<(row+1)*8, id: \.self) { i in
                                TextField("", text: $favoriteEmoji[i])
                                    .textFieldStyle(EmojiTextFieldStyle())
                                    .onChange(of: favoriteEmoji[i]) { _, value in
                                        EndEditCell(index: i)
                                    }
                                    .focused($focusCell, equals: i)
                                    .simultaneousGesture(
                                        TapGesture().onEnded {
                                            favoriteEmoji[i] = ""
                                        }
                                    )
                            }
                        }.listRowSeparator(.hidden)
                    }
                }
            }
        }
        .navigationTitle(Localization.FavoriteEmojiScreen.title)
        .onTapGesture() {
            UIApplication.shared.endEditing()
        }
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
                if let cellIndex = focusCell, cellIndex >= favoriteEmoji.count - 1 {
                    focusCell = -1
                    UIApplication.shared.endEditing()
                }
            }
        }
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
