//
//  SpacebarPurchaseView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/9/26.
//

import Foundation
import SwiftUI

private let SpacebarPurchaseLocalize = Localization.PreferencesScreen.SpacebarPurchase.self

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
                    Text(SpacebarPurchaseLocalize.title)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                    HStack (alignment: .center) {
                        Spacebar(animate: true, glow: true)
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                    
                    Text(String(format: SpacebarPurchaseLocalize.bodyFormat, purchasePrice, gamblePrice, Int(round(gambleWinProbability * 100))))
                    
                    HStack {
                        Spacer()
                        Text(SpacebarPurchaseLocalize.choicePrompt)
                            .font(.system(size: 20, weight: .semibold))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.vertical, 16)

                    DefaultButton(label: {
                        Text(SpacebarPurchaseLocalize.learnGesturesTitle)
                        Text(SpacebarPurchaseLocalize.learnGesturesSubtitle)
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
                    
                    RestorePurchasesButton()
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
            Text(SpacebarPurchaseLocalize.purchaseButtonTitle)
            Text(String(format: SpacebarPurchaseLocalize.purchaseButtonSubtitleFormat, price))
                .opacity(0.6)
                .font(.subheadline)
        }) { purchaseAlertPresented = true  }
        .alert(Text(SpacebarPurchaseLocalize.purchaseAlertTitle), isPresented: $purchaseAlertPresented, actions: {
            Button(action: {}) {
                Text(SpacebarPurchaseLocalize.sorryIllBeBetter)
            }
            .keyboardShortcut(.defaultAction)
            Button(action: { onContinue() }) {
                Text(String(format: SpacebarPurchaseLocalize.purchaseAlertConfirmFormat, price))
            }
            .keyboardShortcut(.cancelAction)
        }, message: {
            Text(SpacebarPurchaseLocalize.purchaseAlertMessage)
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
            Text(SpacebarPurchaseLocalize.gambleButtonTitle)
            Text(String(format: SpacebarPurchaseLocalize.gambleButtonSubtitleFormat, price))
                .opacity(0.6)
                .font(.subheadline)
        }) { gambleAlertPresented = true }
        .alert(Text(SpacebarPurchaseLocalize.gambleAlertTitle), isPresented: $gambleAlertPresented, actions: {
            Button(action: {}) {
                Text(SpacebarPurchaseLocalize.sorryIllBeBetter)
            }
                .keyboardShortcut(.defaultAction)
            Button(action: { onContinue() }) {
                Text(String(format: SpacebarPurchaseLocalize.gambleAlertConfirmFormat, price))
            }
                .keyboardShortcut(.cancelAction)
        }, message: {
            Text(String(format: SpacebarPurchaseLocalize.gambleAlertMessageFormat, Int(round(winProbability * 100))))
        })
        .tint(nil)
    }
}

struct RestorePurchasesButton: View {
    @EnvironmentObject var iapManager: InAppPurchasesManager
    @Environment(\.dismiss) private var dismiss
    
    @State var loading = false

    var body: some View {
        Button(action: {
            loading = true
            Task { 
                await iapManager.UpdatePurchaseStatus()
                if iapManager.isSpacebarUnlocked { dismiss() }
                loading = false
            } 
        }, label: {
            HStack {
                if loading { ProgressView().tint(.gray).scaleEffect(0.75) }
                Text(SpacebarPurchaseLocalize.restorePurchases)
            }
        })
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
            Text(SpacebarPurchaseLocalize.requestForFreeTitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(uiColor:.systemGray2))
                .font(.footnote)
        })
        .frame(maxWidth: .infinity)
        .alert(Text(SpacebarPurchaseLocalize.requestForFreeAlertTitle), isPresented: $forFreeAlertPresented, actions: {
            Button(action: { EmailGrant() }) {
                Text(SpacebarPurchaseLocalize.requestForFreeAlertConfirm)
            }
                .keyboardShortcut(.defaultAction)
            Button(action: {}) {
                Text(SpacebarPurchaseLocalize.requestForFreeAlertDismiss)
            }
                .keyboardShortcut(.cancelAction)
        }, message: {
            Text(SpacebarPurchaseLocalize.requestForFreeAlertMessage)
        })
        .tint(nil)
    }

    private func EmailGrant() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "grant@finaletodo.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: SpacebarPurchaseLocalize.requestForFreeEmailSubject),
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
            Text(SpacebarPurchaseLocalize.orDivider)
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
        .environmentObject(InAppPurchasesManager())
}
