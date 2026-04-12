//
//  SpacebarPurchaseView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI

struct SpacebarPurchaseView: View {
    let onSpacebarActivated: () -> Void
    
    @EnvironmentObject var iapManager: InAppPurchasesManager
    
    @State var presentLootboxSheet = false
    
    @Environment(\.dismiss) private var dismiss

    var purchasePrice: String { iapManager.spacebarProduct?.displayPrice ?? "$99" }
    var gamblePrice: String { iapManager.spacebarGambleProduct?.displayPrice ?? "$0.99" }
    let gambleWinProbability: Double = 0.1
    
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
                        Spacebar(animate: true, glow: true)
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
                    Text("If you have more money than brains (duh, you can't even be bothered to learn the swipe-right gesture), you can buy The Spacebar outright for \(purchasePrice).")
                    Text("Or, if you are poor with no end in sight, you can spin the wheel for \(gamblePrice) and get a \(Int(round(gambleWinProbability * 100)))% chance of winning The Spacebar.")
                    HStack {
                        Spacer()
                        Text("So, what will it be?")
                            .font(.system(size: 20, weight: .semibold))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.vertical, 16)

                    DefaultButton(label: {
                        Text("I am sorry")
                        Text("I will learn gestures.")
                            .opacity(0.6)
                            .font(.subheadline)
                    }) { dismiss() }
                    
                    OptionsDivider()
                    
                    PurchaseSpacebarButton(price: purchasePrice) {
                        Task { await iapManager.PurchaseSpacebar(onSuccess: {
                            onSpacebarActivated()
                            dismiss()
                        }) }
                    }
                    GambleSpacebarButton(winProbability: gambleWinProbability, price: gamblePrice) {
                        Task { await iapManager.PurchaseSpacebarGamble(onSuccess: { presentLootboxSheet = true }) }
                    }
                    
                    RestorePurchasesButton() {
                        Task { await iapManager.UpdatePurchaseStatus() }
                    }
                    .padding(.top, 64)
                    
                    RequestForFreeButton()
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
        .sheet(isPresented: $presentLootboxSheet) {
            SpacebarLootboxView(winProbability: gambleWinProbability, onSpacebarActivated: {
                onSpacebarActivated()
                dismiss()
            })
        }
    }
}

struct PurchaseSpacebarButton: View {
    @State var purchaseAlertPresented = false
    
    let price: String
    let onContinue: () -> Void
    
    var body: some View {
        DefaultButton(.outline, label: {
            Text("I'm rich and useless.")
            Text("I'll buy it for \(price).")
                .opacity(0.6)
                .font(.subheadline)
        }) { purchaseAlertPresented = true  }
        .alert("Does it feel good to be rich?", isPresented: $purchaseAlertPresented, actions: {
            Button("Sorry, I'll be better.") {}
            .keyboardShortcut(.defaultAction)
            Button("I need to buy it for \(price).") { onContinue() }
            .keyboardShortcut(.cancelAction)
        }, message: {
            Text("Why are you wasting your money? Just go learn the swipe gestures, they are much better.")
        })
        .tint(nil)
    }
}

struct GambleSpacebarButton: View {
    let winProbability: Double
    @State var gambleAlertPresented = false
    
    let price: String
    let onContinue: () -> Void
    
    var body: some View {
        DefaultButton(.outline, label: {
            Text("I'm poor because I gamble.")
            Text("I'll spin for \(price).")
                .opacity(0.6)
                .font(.subheadline)
        }) { gambleAlertPresented = true }
        .alert("Is this a good life?", isPresented: $gambleAlertPresented, actions: {
            Button("Sorry, I'll be better.") {}
                .keyboardShortcut(.defaultAction)
            Button("I'm addicted, I'll spin for \(price).") { onContinue() }
                .keyboardShortcut(.cancelAction)
        }, message: {
            Text("Are you about to gamble in an app? Its only a \(Int(round(winProbability * 100)))% chance, go learn the swipe gestures instead. You'll thank me later.")
        })
        .tint(nil)
    }
}

struct RestorePurchasesButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button("Restore purchases") { onTap() }
            .frame(maxWidth: .infinity)
            .foregroundStyle(Color(uiColor:.systemGray2))
            .font(.footnote)
    }
}

struct RequestForFreeButton: View {
    
    @State var forFreeAlertPresented = false
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button(action: {
            forFreeAlertPresented = true
        }, label: {
            Text("Psss, come here, kitty. Still want your spacebar for free?")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(uiColor:.systemGray2))
                .font(.footnote)
        })
        .frame(maxWidth: .infinity)
        .alert("Uuugh, fine", isPresented: $forFreeAlertPresented, actions: {
            Button("I'll do as you say, boss.") { EmailGrant() }
                .keyboardShortcut(.defaultAction)
            Button("Fuck you, man.") { }
                .keyboardShortcut(.cancelAction)
        }, message: {
            Text("I guess... if you really can't be bothered to learn gestures...\n\nEmail me at grant@finaletodo.com with the worst insult towards yourself. If I like it, I'll see what I can do.")
        })
        .tint(nil)
    }

    private func EmailGrant() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "grant@finaletodo.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Please, please, please, I beg you, Grant, give me a spacebar."),
        ]

        guard let emailURL = components.url else { return }
        openURL(emailURL)
    }
}

struct Spacebar: View {
    let animate: Bool
    let glow: Bool
    let width: CGFloat = 200
    static let rotationAmount: Double = 5
    let rotationDuration: Double = 2
    let height: CGFloat = 40
    
    @State var rotationAngle: Angle = .degrees(0)
    
    var body: some View {
         ZStack {
             if glow { BackgroundGlow() }
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
             ProcessAnimation(animate: animate)
         }
         .onChange(of: animate) { _, newValue in
             ProcessAnimation(animate: newValue)
         }
     }
    
    func ProcessAnimation (animate: Bool) {
        if (animate) {
            rotationAngle = .degrees(-Spacebar.rotationAmount)
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                rotationAngle = .degrees(Spacebar.rotationAmount)
            }
        } else { rotationAngle = .degrees(0) }
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
    SpacebarPurchaseView(onSpacebarActivated: {})
}
