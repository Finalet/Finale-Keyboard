//
//  SpacebarPurchaseView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI

struct SpacebarPurchaseView: View {

    @State var purchaseAlertPresented = false
    @State var gambleAlertPresented = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
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
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    Text("Awwww, how cute..! You want a spacebar? You want to press a buttom to type a space?")
                    Text("Everyone, look! This little tiny stupid todler can't type without their spacebar. Isn't that adorable?")
                    Text("You can't learn simple swipe gestures? Moving your finger across the screen is too hard? Aw, of course, I should've known you don't have the hand-eye coordination for such advanced locomotion! You poor baby. You poor, stupid, slow, useless, moronic fucking baby.")
                    Text("Fine. Okay. If you REALLY want your spacebar, I'll give it to you. I'll even be generous and give you a choice.")
                    Text("As you might have noticed, we live in a K-shaped economy. Meaning, there is a divergence between the rich and the poor. The investor-class and the permanent under-class.")
                    Text("So, statistically, you are either filthy rich and don't care to waste money. Or, you are drowning in dept with gambling being your only hope for financial stability.")
                    Text("I'll give options for both.")
                    Text("If you have more money than brains (duh, you can't even be bothered to learn the swipe-right gesture), you can buy The Spacebar outright for $99.")
                    Text("Or, if you are poor with no end in sight, you can spin the wheel for $0.99 and get a 10% chance of winning The Spacebar.")
                    HStack {
                        Spacer()
                        Text("So, what will it be?")
                            .font(.system(size: 20, weight: .semibold))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    DefaultButton(label: "I am sorry.", subLabel: "I will learn the gestures.") {
                        dismiss()
                    }
                    OptionsDivider()
                    OutlineButton(label: "I'm rich and useless.", subLabel: "I'll buy it for $99.") {
                        purchaseAlertPresented = true
                    }
                    .alert("Does it feel good to be rich?", isPresented: $purchaseAlertPresented, actions: {
                        Button("Sorry, I'll be better.") {
                            
                        }
                        .keyboardShortcut(.defaultAction)
                        Button("I WANT to buy it for $99.") {
                            
                        }
                        .keyboardShortcut(.cancelAction)
                    }, message: {
                        Text("Why are you wasting your money? Just go learn the swipe gestures, they are much better.")
                    })
                    .tint(nil)
                    
                    OutlineButton(label: "I'm poor because I gamble.", subLabel: "I'll spin for $0.99.") {
                        gambleAlertPresented = true
                    }
                    .alert("Is this a good life?", isPresented: $gambleAlertPresented, actions: {
                        Button("Sorry, I'll be better.") {
                            
                        }
                        .keyboardShortcut(.defaultAction)
                        Button("I'm addicted, I'll spin for $0.99.") {
                            
                        }
                        .keyboardShortcut(.cancelAction)
                    }, message: {
                        Text("Where you about to gamble again? Its only a 10% chance, go learn the swipe gestures instead. You'll thank me later.")
                    })
                    .tint(nil)
                }
                .padding()
            }
            VStack {
                Rectangle()
                    .fill(Color(uiColor: .systemBackground))
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .bottom, endPoint: .top))
                    .frame(height: 60)
                Spacer()
            }
            .ignoresSafeArea()
        }
        .interactiveDismissDisabled()
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
             BackgroundGlow()
             ForEach(0..<6) { i in
                 RoundedRectangle(cornerRadius: 5)
                     .fill(Color(uiColor: .systemGray2))
                     .frame(width: width * (1 - CGFloat(i) * 0.25 / 100), height: height * (1 - CGFloat(i) * 0.25 / 100))
                     .offset(x: CGFloat(i), y: CGFloat(i))
             }
             RoundedRectangle(cornerRadius: 5)
                 .fill(Color(uiColor: .systemGray4).shadow(.inner(color: .white.opacity(0.25), radius: 1, y: 2)))
                 .frame(width: width, height: height)
             Image(systemName: "space")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 30)
                 .fontWeight(.semibold)
         }
         .shadow(color: .black.opacity(0.02), radius: 10, y: 20)
         .rotation3DEffect(rotationAngle, axis: (x: 0, y: 1, z: 0))
         .onAppear {
             withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                 rotationAngle = .degrees(Spacebar.rotationAmount)
             }
         }
     }
}

struct BackgroundGlow: View {
    let size = 100.0
    let radius = 40.0
    let rotationDuration = 20.0
    
    @State var angle: Angle = .degrees(0)
    @State private var isPulsing = false
    
    var body: some View {
        
        ZStack {
            ForEach(0..<3) { i in
                let angle = 2.0 * Double.pi * Double(i) / 3.0
                Circle()
                    .fill(Color.brand)
                    .blur(radius: 20)
                    .opacity(isPulsing ? 0.05 : 0.25)
                    .frame(width: size, height: size)
                    .offset(
                        x: radius * CGFloat(cos(angle)),
                        y: radius * CGFloat(sin(angle))
                    )
                    .animation(
                        .easeInOut(duration: 5).repeatForever(autoreverses: true).delay(Double(i) * 1.5),
                        value: isPulsing
                    )
            }
        }
        .rotationEffect(angle)
        .onAppear {
            withAnimation(.linear(duration: rotationDuration).repeatForever(autoreverses: false)) {
                angle = .degrees(360)
            }
            isPulsing = true
        }
    }
}

struct OptionsDivider: View {
    var body: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(uiColor: .systemGray3))
            Text("or")
                .foregroundStyle(.gray)
                .font(.subheadline)
            Rectangle()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundStyle(Color(uiColor: .systemGray3))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}

struct DefaultButton: View {
    let label: String
    let subLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Text(label)
                    .font(.headline)
                Text(subLabel)
                    .opacity(0.6)
                    .font(.subheadline)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brand.shadow(.inner(color: .white.opacity(0.25), radius: 1, y: 3)))
            )
            .foregroundStyle(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.brand.opacity(0.5), radius: 5, y: 5)
        }
    }
}

struct OutlineButton: View {
    let label: String
    let subLabel: String
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var dark: Bool { return colorScheme == .dark }

    var body: some View {
        Button(action: action) {
            VStack {
                Text(label)
                    .font(.headline)
                Text(subLabel)
                    .opacity(0.6)
                    .font(.subheadline)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemGray6).shadow(.inner(color: .white.opacity(dark ? 0.2 : 0.5), radius: 1, y: 3)))
                    .stroke(Color(uiColor: .systemGray3), lineWidth: dark ? 0 : 1)
            )
            .foregroundStyle(Color.primary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(dark ? 0.5 : 0.1), radius: 2, y: 3)
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
