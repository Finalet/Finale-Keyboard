//
//  TutorialView.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 3/9/22.
//

import Foundation
import SwiftUI

struct TutorialView: View {
    @State var testText = ""
    
    var body: some View {
        GeometryReader { geo in
            VStack (alignment: .leading) {
                TabView {
                    Group {
                        Image("Swipe right").resizable()
                        Image("Swipe right punctuation").resizable()
                        Image("Swipe up down").resizable()
                        Image("Swipe left").resizable()
                        Image("Emoji").resizable()
                        Image("Symbols").resizable()
                        Image("Languages").resizable()
                        Image("Return").resizable()
                        Image("Learn").resizable()
                        Image("Move cursor").resizable()
                    }
                    Image("Toggle autocorrect").resizable()
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .aspectRatio(CGSize(width: 1, height: 0.99), contentMode: .fit)
                TextField(Localization.GesturesGuideScreen.inputFieldPlaceholder, text: $testText)
                    .padding()
                    .background(Color(UIColor.systemGray5))
            }
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture() {
            UIApplication.shared.endEditing()
        }
    }
}

struct TutorialView_Previews: PreviewProvider {
    
    static var previews: some View {
        TutorialView()
    }
}
