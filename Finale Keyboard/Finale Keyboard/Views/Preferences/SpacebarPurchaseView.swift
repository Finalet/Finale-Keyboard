//
//  SpacebarPurchaseView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI

struct SpacebarPurchaseView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Uh oh, someone wants a spacebar?")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                    HStack (alignment: .center) {
                        Spacebar()
                    }
                    .padding(.vertical, 64)
                    .frame(maxWidth: .infinity)
                    Text("Awwww, how cute..! You want a spacebar? You poor baby want to press a key to type a space?")
                    Text("Everyone, look! This little tiny stupid dumb fucking baby can't type without their spacebar. Isn't that adorable?")
                    Text("You can't learn simple swipe gestures? Moving your finger across the screen is too hard? Aw, of course, I should've known you don't have the hand-eye coordination for such advanced locomotion. You poor baby. You poor, stupid, useless, slow, halfwitted, dull, moronic baby.")
                    Text("Fine. Okay. If you really want your spacebar, you can have it. I'll even be generous and give you a choice.")
                    Text("Option 1. For the dumb rich: purchase the spacebar for $99 outright.")
                    Text("Option 2. For the permanent underclass: gamble for $0.99 and get a 1 in 10 chance of unlocking the spacebar.")
                    PurchaseButton()
                    GambleButton()
                }
                .padding()
            }
            .softScrollEdgeEffectIA(.vertical)
        }
    }
}

struct Spacebar: View {
    static let rotationAmount: Double = 5
    let rotationDuration: Double = 2
    let width: CGFloat = 200
    let height: CGFloat = 40
    
    @State var rotationAngle: Angle = .degrees(-Spacebar.rotationAmount)
    
    var body: some View {
         ZStack {
             ForEach(0..<6) { i in
                 RoundedRectangle(cornerRadius: 5)
                     .fill(Color(uiColor: .systemGray2))
                     .frame(width: width, height: height)
                     .offset(x: CGFloat(i), y: CGFloat(i))
             }
             RoundedRectangle(cornerRadius: 5)
                 .fill(Color(uiColor: .systemGray4).shadow(.inner(color: .white.opacity(0.25), radius: 0, y: 3)))
                 .frame(width: width, height: height)
             Image(systemName: "space")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 30)
                 .fontWeight(.semibold)
         }
         .shadow(color: .black.opacity(0.03), radius: 10, y: 20)
         .rotation3DEffect(rotationAngle, axis: (x: 0, y: 1, z: 0))
         .onAppear {
             withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: true)) {
                 rotationAngle = .degrees(Spacebar.rotationAmount)
             }
         }
     }
}

struct PurchaseButton: View {
    var body: some View {
        Button(action: {}) {
            Text("I'm rich and useless. I'll buy it for $99.")
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.brand.shadow(.inner(color: .white.opacity(0.25), radius: 2, y: 5)))
                )
                .fontWeight(.medium)
                .foregroundStyle(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.brand.opacity(0.5), radius: 5, y: 5)
        }
    }
}

struct GambleButton: View {
    var body: some View {
        Button(action: {}) {
            Text("I'm poor because I gamble. I'll spin for $0.99")
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .systemGray6).shadow(.inner(color: .white.opacity(0.5), radius: 2, y: 5)))
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
                )
                .fontWeight(.medium)
                .foregroundStyle(Color.black)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
        }
    }
}

extension View {
    @ViewBuilder
    func softScrollEdgeEffectIA(_ forEdge: Edge.Set) -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: forEdge)
        } else {
            self
        }
    }
}

#Preview {
    SpacebarPurchaseView()
}
