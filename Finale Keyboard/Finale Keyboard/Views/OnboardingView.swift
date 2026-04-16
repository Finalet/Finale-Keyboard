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
    
    @State var step: Int = 0
    
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
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
                    WelcomeStep()
                } else if step == 1 {
                    SetupStep()
                } else if step == 2 {
                    GesturesStep()
                } else if step == 3 {
                    AllSetStep()
                }
                
                DefaultButton(disabled: !canContinue, label: {
                    Text(step == 0 ? "Let's get started" : step == 3 ? "Done" : "Continue")
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
}

struct WelcomeStep: View {
    var body: some View {
        OnboardingBase(title: "Welcome to\nFinale Keyboard", description: "Gesture-based minimal keyboard.") {
            VStack (spacing: 32) {
                VStack (spacing: 16) {
                    FeatureRow(iconName: "hand.draw", title: "Gesture-based", description: "Better way of typing with intuitive swipe gestures.")
                    FeatureRow(iconName: "keyboard", title: "Minimal", description: "Takes up less space on your screen, so you can focus on what's actually important.")
                    FeatureRow(iconName: "sparkles", title: "Smart", description: "Learns your vocabulary, adjusts touch zones when predicting your next word, offers an effecient shortcuts system.")
                }
            }
        }
        .padding(.vertical, 32)
    }
}

struct SetupStep: View {
    
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
    typealias Localize = Localization.HomeScreen
    
    var body: some View {
        OnboardingBase(
            title: "First, let's set things up",
            description: "Enable Finale Keyboard and give it full access.") {
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
    }
    
    func OpenSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

struct GesturesStep: View {
    @State var typingField: String = ""
    @State var presentGesturesGuide = false
    
    var body: some View {
        OnboardingBase(
            title: "Let's practice gestures",
            description: "While you type characters as usual, all other actions, like typing spaces, deleting words, or autocorrections are done with gestures.") {
                VStack (spacing: 32) {
                    VStack (spacing: 16) {
                        SwipeRow(direction: .right(), label: "Insert space or punctuations")
                        SwipeRow(direction: .vertical(), label: "Cycle suggestions")
                        SwipeRow(direction: .left(), label: "Delete word")
                        SwipeRow(direction: .left("on backspace"), label: "Use emoji")
                        Button(action: { presentGesturesGuide = true }) {
                            HStack {
                                Text("View all gestures")
                                Image(systemName: "chevron.right")
                                    .scaleEffect(0.8)
                            }
                        }
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
            .sheet(isPresented: $presentGesturesGuide) {
                NavigationStack {
                    GesturesGuideView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing, content: {
                                Button(action: { presentGesturesGuide = false }) {
                                    Image(systemName: "xmark")
                                }
                                .tint(.primary)
                            })
                        }
                }
            }
    }
}

struct AllSetStep: View {
    var body: some View {
        OnboardingBase(title: "You are all set", description: "Gestures might take a few days getting used to, but, once they become second nature, you'll refuse to type without them.\n\nFinale Keyboard has much more to offer. Feel free to explore these festures once you settle down.") {
            VStack (spacing: 32) {
                VStack (spacing: 16) {
                    FeatureRow(iconName: "square.filled.on.square", title: "Shortcuts", description: "Type emojis, dates, contacts, or anything else with quick shortcuts.")
                    FeatureRow(iconName: "heart", title: "Favorite emoji", description: "Save your most used emojis under your fingertips.")
                    FeatureRow(iconName: "keyboard", title: "Dynamic touch zones", description: "Type faster with keys that predict your next word.")
                }
            }
        }
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
            SwipeGestureView(direction)
        }
    }
}

struct FeatureRow: View {
    let iconName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack (alignment: .top, spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .frame(width: 40)
                .offset(y: 4)
            VStack (alignment: .leading) {
                Text(title)
                    .fontWeight(.semibold)
                    .font(.headline)
                    .foregroundStyle(Color.brand)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.leading)
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


#Preview {
    OnboardingView(finishedOnboarding: Binding.constant(false))
}
