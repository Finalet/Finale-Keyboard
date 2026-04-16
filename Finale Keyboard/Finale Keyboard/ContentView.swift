//
//  ContentView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 1/31/22.
//

import SwiftUI
import Keyboard

struct ContentView: View {
    @UserDefaultState("FINALE_DEV_APP_finishedOnboarding", false) var finishedOnboarding: Bool
    @State var showOnboarding = false
    
    @StateObject private var iapManager = InAppPurchasesManager()
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
    
    @State var testText = ""
    
    typealias Localize = Localization.HomeScreen
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(Localize.inputFieldTitle)) {
                    TextField(Localize.inputFieldPlaceholder, text: $testText)
                }
                Section(header: Text(Localize.preferencesTitle)) {
                    ListNavigationLink(destination: FavoriteEmojiView()) {
                        Label(title: {
                            Text(Localize.favoriteEmojiRow)
                        }, icon: {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                        })
                    }
                    ListNavigationLink(destination: ShortcutsView()) {
                        Label(title: {
                            Text(Localize.shortcutsRow)
                        }, icon: {
                            Image(systemName: "keyboard")
                        })
                    }
                    ListNavigationLink(destination: LanguagesView()) {
                        Label(title: {
                            Text(Localize.languagesRow)
                        }, icon: {
                            Image(systemName: "globe")
                        })
                    }
                    ListNavigationLink(destination: DictionaryView()) {
                        Label(title: {
                            Text(Localize.dictionaryRow)
                        }, icon: {
                            Image(systemName: "character.book.closed")
                        })
                    }
                    ListNavigationLink(destination: PreferencesView()) {
                        Label(title: {
                            Text(Localize.preferencesRow)
                        }, icon: {
                            Image(systemName: "square.and.pencil")
                        })
                    }
                }
                Section(header: Text(Localize.helpTitle)){
                    ListNavigationLink(destination: GesturesGuideView()) {
                        Label(title: {
                            Text(Localize.gesturesGuideRow)
                        }, icon: {
                            Image(systemName: "hand.draw")
                        })
                    }
                }
                Section(header: Text(Localize.setupTitle), footer: Text(Localize.setupFooter)) {
                    EnabledListItem(
                        isEnabled: keyboardState.isKeyboardEnabled,
                        enabledText: Localize.keyboardEnabledAlert,
                        disabledText: Localize.keyboardDisabledAlert)
                    EnabledListItem(
                        isEnabled: keyboardState.isFullAccessEnabled,
                        enabledText: Localize.keyboardFullAccessEnabled,
                        disabledText: Localize.keyboardFullAccessDisabled)
                    if !keyboardState.isKeyboardEnabled || !keyboardState.isFullAccessEnabled {
                        ListNavigationButton(action: OpenSettings) {
                            Label(Localize.systemSettingsRow, systemImage: "gearshape")
                        }
                    }
                }
                Section(header: Text("Developer")) {
                    ListNavigationButton(action: OpenTwitter) {
                        Label("Profile", systemImage: "person")
                    }
                    ListNavigationButton(action: ContactDeveloper) {
                        Label("Message me", systemImage: "message")
                    }
                    ListNavigationLink(destination: MoreView()) {
                        Label(Localize.moreRow, systemImage: "ellipsis.circle")
                    }
                }
            }
            .navigationTitle("Finale Keyboard")
        }
        .tint(.brand)
        .environmentObject(keyboardState)
        .environmentObject(iapManager)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: UIApplication.shared.addTapAnywhereToDismissKeyboard)
        .onAppear { if !finishedOnboarding { showOnboarding = true } }
        .sheet(isPresented: $showOnboarding) { OnboardingView(onDone: { finishedOnboarding = true; showOnboarding = false }) }
    }
    
    func OpenSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func OpenTwitter() {
        if let url = URL(string: "https://twitter.com/grantogany") { UIApplication.shared.open(url) }
    }
    func ContactDeveloper() {
        if let url = URL(string: "mailto:grant@finaletodo.com") { UIApplication.shared.open(url) }
    }
}

struct EnabledListItem: View {
    
    let isEnabled: Bool
    let enabledText: String
    let disabledText: String
    var disabledColor: Color = .orange
    
    var body: some View {
        ListItem {
            Label(
                isEnabled ? enabledText : disabledText,
                systemImage: isEnabled ? "checkmark" : "exclamationmark.triangle")
        }
        .foregroundColor(isEnabled ? .green : disabledColor)
    }
}

public struct ListNavigationButton<Content: View>: View {
    
    public init(
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    private let action: () -> Void
    @ViewBuilder private let content: () -> Content
    
    public var body: some View {
        ListButton(action: action) {
            HStack {
                content()
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.footnote.bold())
                    .foregroundColor(.secondary)
                    .opacity(0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

public struct ListButton<Content: View>: View {
    
    public init(
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    private let action: () -> Void
    @ViewBuilder private let content: () -> Content
    
    public var body: some View {
        Button(action: action) {
            ListItem(content: content)
        }
    }
}

public struct ListItem<Content: View>: View {
    
    public init(
        @ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    @ViewBuilder private let content: () -> Content
    
    public var body: some View {
        HStack {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

public struct ListNavigationLink<Content: View, Destination: View>: View {
    
    public init(
        destination: Destination,
        @ViewBuilder content: @escaping () -> Content) {
        self.destination = { destination }
        self.content = content
    }
    
    public init(
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder content: @escaping () -> Content) {
        self.destination = destination
        self.content = content
    }
    
    @ViewBuilder private let destination: () -> Destination
    @ViewBuilder private let content: () -> Content
    
    public var body: some View {
        NavigationLink(destination: destination) {
            ListItem(content: content)
        }
    }
}

#Preview {
    ContentView()
}
