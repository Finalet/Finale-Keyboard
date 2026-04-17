//
//  OnboardingView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/12/26.
//

import Foundation
import SwiftUI
import UIKit

struct OnboardingView: View {
    let onDone: () -> Void
    
    @State var step: Int = 0
    
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
    var canContinue: Bool { step == 1 ? (keyboardState.isKeyboardEnabled && keyboardState.isFullAccessEnabled) : true  }
    typealias Localize = Localization.OnboardingScreen
    
    func Next() { withAnimation { step += 1 } }
    func Back() { withAnimation { step -= 1 } }
    func Done() { onDone() }
    
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
                    Text(step == 0 ? Localize.getStarted : step == 3 ? Localization.Actions.done : Localization.Actions.continueButton)
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
    typealias Localize = Localization.OnboardingScreen.WelcomeStep

    var body: some View {
        OnboardingBase(title: Localize.title, description: Localize.description, showAppIcon: true) {
            VStack (spacing: 32) {
                VStack (spacing: 16) {
                    FeatureRow(iconName: "hand.draw", title: Localize.gestureBasedTitle, description: Localize.gestureBasedDescription)
                    FeatureRow(iconName: "keyboard", title: Localize.minimalTitle, description: Localize.minimalDescription)
                    FeatureRow(iconName: "sparkles", title: Localize.smartTitle, description: Localize.smartDescription)
                }
            }
        }
        .padding(.vertical, 32)
    }
}

struct SetupStep: View {
    
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
    typealias HomeLocalize = Localization.HomeScreen
    typealias Localize = Localization.OnboardingScreen.SetupStep
    
    var body: some View {
        OnboardingBase(
            title: Localize.title,
            description: Localize.description) {
                VStack(spacing: 32) {
                    EnabledListItem(
                        isEnabled: keyboardState.isKeyboardEnabled,
                        enabledText: HomeLocalize.keyboardEnabledAlert,
                        disabledText: HomeLocalize.keyboardDisabledAlert)
                    EnabledListItem(
                        isEnabled: keyboardState.isFullAccessEnabled,
                        enabledText: HomeLocalize.keyboardFullAccessEnabled,
                        disabledText: HomeLocalize.keyboardFullAccessDisabled)
                    if !keyboardState.isKeyboardEnabled || !keyboardState.isFullAccessEnabled {
                        ListNavigationButton(action: OpenSettings) {
                            Label(HomeLocalize.systemSettingsRow, systemImage: "gearshape")
                        }
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
    typealias Localize = Localization.OnboardingScreen.GesturesStep
    
    var body: some View {
        OnboardingBase(
            title: Localize.title,
            description: Localize.description) {
                VStack (spacing: 32) {
                    VStack (spacing: 16) {
                        SwipeRow(direction: .right(), label: Localize.insertSpaceOrPunctuations)
                        SwipeRow(direction: .vertical(), label: Localize.cycleSuggestions)
                        SwipeRow(direction: .left(), label: Localize.deleteWord)
                        SwipeRow(direction: .left(Localization.GesturesGuideScreen.Directions.onBackspace), label: Localize.useEmoji)
                        Button(action: { presentGesturesGuide = true }) {
                            HStack {
                                Text(Localize.viewAllGestures)
                                Image(systemName: "chevron.right")
                                    .scaleEffect(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.gray)
                        .font(.system(size: 14))
                    }
                    
                    TextField(Localization.HomeScreen.inputFieldPlaceholder, text: $typingField)
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
    typealias Localize = Localization.OnboardingScreen.AllSetStep

    var body: some View {
        OnboardingBase(title: Localize.title, description: Localize.description) {
            VStack (spacing: 32) {
                VStack (spacing: 16) {
                    FeatureRow(iconName: "square.filled.on.square", title: Localization.Shortcuts.title, description: Localize.shortcutsDescription)
                    FeatureRow(iconName: "heart", title: Localization.FavoriteEmojiScreen.title, description: Localize.favoriteEmojiDescription)
                    FeatureRow(iconName: "keyboard", title: Localization.PreferencesScreen.DynamicTouchZones.pageTitle, description: Localize.dynamicTouchZonesDescription)
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
    let showAppIcon: Bool
    let content: () -> Content
    
    @Environment(\.colorScheme) private var colorScheme
    var dark: Bool { return colorScheme == .dark }
    
    init(title: String, description: String, showAppIcon: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.showAppIcon = showAppIcon
        self.content = content
    }
    
    private var appIconImage: UIImage? {
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let iconFileName = iconFiles.last
        else {
            return nil
        }
        
        return UIImage(named: iconFileName)
    }
    
    var body: some View {
        VStack (spacing: 32) {
            if showAppIcon, let appIconImage {
                Image(uiImage: appIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(dark ? 1 : 0.25), radius: 12, y: 8)
            }
            
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
    OnboardingView(onDone: {})
}
