//
//  OnboardingView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/12/26.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @Binding var finishedOnboarding: Bool
    
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
    typealias Localize = Localization.HomeScreen
    
    @State var step: Int = 0
    @State var typingField: String = ""
    
    var canContinue: Bool { step == 1 ? (keyboardState.isKeyboardEnabled && keyboardState.isFullAccessEnabled) : true  }
    
    @Environment(\.dismiss) private var dismiss
    
    func Next() { withAnimation { step += 1 } }
    func Back() { withAnimation { step -= 1 } }
    func Done() {
        finishedOnboarding = true
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            VStack (spacing: 32) {
                if step == 0 {
                    OnboardingBase(title: "Welcome to\nFinale Keyboard", description: "Gesture-based minimal keyboard.") {}
                        .padding(.vertical, 32)
                } else if step == 1 {
                    OnboardingBase(
                        title: "First, let's set things up",
                        description: "Enable the keyboard and give it full access.") {
                            VStack(spacing: 32) {
                                EnabledListItem(
                                    isEnabled: keyboardState.isKeyboardEnabled,
                                    enabledText: Localize.keyboardEnabledAlert,
                                    disabledText: Localize.keyboardDisabledAlert)
                                EnabledListItem(
                                    isEnabled: keyboardState.isFullAccessEnabled,
                                    enabledText: Localize.keyboardFullAccessEnabled,
                                    disabledText: Localize.keyboardFullAccessDisabled)
                                ListNavigationButton(action: OpenSettings) {
                                    Label(Localize.systemSettingsRow, systemImage: "gearshape")
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .secondarySystemBackground).shadow(.inner(color: .black.opacity(0.1), radius: 2)))
                                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                            )
                        }
                } else if step == 2 {
                    OnboardingBase(
                        title: "Let's learn gestures",
                        description: "Finale Keyboard is not a regular keyboard. While you type characters as usual, all other actions, like typing spaces, deleting words, or autocorrections are done with gestures.") {
                            VStack (spacing: 32) {
                                VStack (spacing: 16) {
                                    SwipeRow(direction: .right(), label: "Insert space or punctuations")
                                    SwipeRow(direction: .vertical(), label: "Cycle suggestions")
                                    SwipeRow(direction: .left(), label: "Delete word")
                                    SwipeRow(direction: .left("on backspace"), label: "Use emoji")
                                    Text("And many others...")
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 14))
                                }
                                
                                TextField("Try typing here", text: $typingField)
                                    .multilineTextAlignment(.leading)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(uiColor: .secondarySystemBackground).shadow(.inner(color: .black.opacity(0.1), radius: 2)))
                                            .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                } else if step == 3 {
                    OnboardingBase(title: "That's all!", description: "Gestures might take a few days getting used to, but, once they become second nature, you won't want to type without them.") {}
                }
                
                DefaultButton(disabled: !canContinue, label: {
                    Text(step == 3 ? "Done" : "Continue")
                }) {
                    if step == 3 { Done() }
                    else { Next() }
                }
            }
            .simultaneousGesture(TapGesture().onEnded({
                UIApplication.shared.endEditing()
            }))
            .toolbar {
                if step != 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { Back() }, label: { Image(systemName: "arrow.left") })
                            .tint(Color(uiColor: .label))
                    }
                }
            }
            .padding(16)
        }
        .interactiveDismissDisabled()
    }
    
    func OpenSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

struct SwipeRow: View {
    let direction: SwipeDirection
    let label: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Swipe(direction)
        }
    }
}

struct Swipe: View {
    let direction: SwipeDirection
    
    init(_ direction: SwipeDirection) {
        self.direction = direction
    }
    
    var body: some View {
        Text("swipe \(direction.label)  \(direction.icon)")
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.brand.opacity(0.1))
                        .stroke(Color.brand.opacity(0.3), lineWidth: 1)
                        .shadow(color: Color.brand, radius: 2, y: 2)
                }
            )
            .foregroundStyle(Color.brand)
    }
}

struct OnboardingBase<Content>: View where Content : View {
    let title: String
    let description: String
    let content: () -> Content
    
    init(title: String, description: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.content = content
    }
    
    var body: some View {
        VStack (spacing: 32) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
            
            Text(description)
                .font(.system(size: 16))
                .foregroundStyle(.gray)
            
            Spacer()
            
            content()
        }
        .background(Color(uiColor: .systemBackground))
        .multilineTextAlignment(.center)
    }
}

enum SwipeDirection {
    case up(String = "")
    case right(String = "")
    case down(String = "")
    case left(String = "")
    case vertical(String = "")
    
    var icon: String {
        switch(self) {
            case .up: return "↑"
            case .right: return "→"
            case .down: return "↓"
            case .left: return "←"
            case .vertical: return "⇅"
        }
    }
    
    var label: String {
        switch (self) {
            case .up(let label): return "up\(!label.isEmpty ? " \(label)" : "")"
            case .right(let label): return "right\(!label.isEmpty ? " \(label)" : "")"
            case .down(let label): return "down\(!label.isEmpty ? " \(label)" : "")"
            case .left(let label): return "left\(!label.isEmpty ? " \(label)" : "")"
            case .vertical(let label): return "up or down\(!label.isEmpty ? " \(label)" : "")"
        }
    }
}

#Preview {
    OnboardingView(finishedOnboarding: Binding.constant(false))
}
