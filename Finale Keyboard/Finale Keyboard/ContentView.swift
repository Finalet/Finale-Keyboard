//
//  ContentView.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 1/31/22.
//

import SwiftUI
import Keyboard

struct ContentView: View {
    
    @StateObject private var keyboardState = KeyboardEnabledState(bundleId: "com.Grant151.Finale-Keyboard.Keyboard")
    
    @State var favoriteEmoji = [String](repeating: "", count: 32)
    @State var testText = ""
    
    @State var EN_enabled = true
    @State var RU_enabled = false
    
    let suiteName = "group.finale-keyboard-cache"
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Try it out")) {
                    TextField("Try typing something here", text: $testText)
                }
                Section(header: Text("Preferences")) {
                    ListNavigationLink(destination: FavoriteEmoji(favoriteEmoji: $favoriteEmoji)) {
                        Label(title: {
                                    Text("Favorite emoji")
                                }, icon: {
                                    Image(systemName: "heart")
                                        .foregroundColor(.red)
                                } )
                    }
                    ListNavigationLink(destination: LanguagesSettings(EN_enabled: $EN_enabled, RU_enabled: $RU_enabled)) {
                        Label(title: {
                                    Text("Languages")
                                }, icon: {
                                    Image(systemName: "globe")
                                        .foregroundColor(.blue)
                                } )
                    }
                    ListNavigationLink(destination: DictionaryListView()) {
                        Label(title: {
                                    Text("Dictionary")
                                }, icon: {
                                    Image(systemName: "character.book.closed")
                                        .foregroundColor(.blue)
                                } )
                    }
                }
                Section(header: Text("Setup"), footer: footerText) {
                    EnabledListItem(
                        isEnabled: isKeyboardEnabled,
                        enabledText: "Keyboard is enabled",
                        disabledText: "Keyboard is disabled")
                    EnabledListItem(
                        isEnabled: isFullAccessEnabled,
                        enabledText: "Full Access is enabled",
                        disabledText: "Full Access is disabled")
                    ListNavigationButton(action: openSettings) {
                        Label("System settings", systemImage: "gearshape")
                    }
                }
                Section(header: Text("Help")){
                    ListNavigationLink(destination: TutorialView()) {
                        Label(title: {
                                    Text("Gestures tutorial")
                                }, icon: {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundColor(.blue)
                                } )
                    }
                    ListNavigationButton(action: ContactDeveloper) {
                        Label("Contact developer", systemImage: "message")
                    }
                }
            }.navigationTitle("Finale Keyboard")
        }
        .environmentObject(keyboardState)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear() {
            LoadEmojiArray()
            LoadEnabledLocales()
        }
    }
    
    func LoadEmojiArray () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        let array = userDefaults?.array(forKey: "FINALE_DEV_APP_favorite_emoji") as? [String]
        if array == nil {
            favoriteEmoji = [String](repeating: "", count: 32)
        } else {
            favoriteEmoji = array!
        }
    }
    func LoadEnabledLocales () {
        let userDefaults = UserDefaults(suiteName: suiteName)
        
        EN_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_en_locale_enabled") == nil ? true : userDefaults?.bool(forKey: "FINALE_DEV_APP_en_locale_enabled") ?? true
        RU_enabled = userDefaults?.value(forKey: "FINALE_DEV_APP_ru_locale_enabled") == nil ? false : userDefaults?.bool(forKey: "FINALE_DEV_APP_ru_locale_enabled") ?? true
    }
}

private extension ContentView {
    
    var footerText: some View {
        Text("You should enable Finale keyboard under system settings, then select it with 🌐 when typing.")
    }
}

private extension ContentView {
    
    var isFullAccessEnabled: Bool {
        keyboardState.isFullAccessEnabled
    }
    
    var isKeyboardEnabled: Bool {
        keyboardState.isKeyboardEnabled
    }
    
    func openSettings() {
        guard let url = URL.keyboardSettings else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func ContactDeveloper() {
        if let url = URL(string: "https://twitter.com/grantogany") {
            UIApplication.shared.open(url)
        }
    }
}

struct EnabledListItem: View {
    
    let isEnabled: Bool
    let enabledText: String
    let disabledText: String
    
    var body: some View {
        ListItem {
            Label(
                isEnabled ? enabledText : disabledText,
                systemImage: isEnabled ? "checkmark" : "exclamationmark.triangle")
        }.foregroundColor(isEnabled ? .green : .orange)
    }
}

struct EnabledListItem_Previews: PreviewProvider {
    
    static var previews: some View {
        EnabledListItem(isEnabled: true, enabledText: "Enabled", disabledText: "Disabled")
        EnabledListItem(isEnabled: false, enabledText: "Enabled", disabledText: "Disabled")
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
                ListDisclosureIndicator()
            }
        }.buttonStyle(.plain)
    }
}

struct ListNavigationButtonItem_Previews: PreviewProvider {
    
    struct Preview: View {
        
        @State var isToggled = false
        
        var body: some View {
            NavigationView {
                List {
                    ListItem {
                        Text("Is toggled: \(isToggled ? 1 : 0)")
                    }
                    ListItem {
                        NavigationLink("Navigation link", destination: Text("HEJ"))
                    }
                    ListNavigationButton(action: { isToggled.toggle() }, content: {
                        Text("Toggle")
                    })
                }
            }
        }
    }
    
    static var previews: some View {
        Preview()
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

struct ListButton_Previews: PreviewProvider {
    
    struct Preview: View {
        
        @State var isToggled = false
        
        var body: some View {
            List {
                ListItem {
                    Text("Is toggled: \(isToggled ? 1 : 0)")
                }
                ListButton(action: toggle) {
                    Text("Toggle")
                }
            }
        }
        
        func toggle() {
            isToggled.toggle()
        }
    }
    
    static var previews: some View {
        Preview()
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
            content().padding(.vertical, 5)
        }
        .frame(minHeight: 45)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ListItem_Previews: PreviewProvider {
    
    static var previews: some View {
        List {
            ListItem {
                Text("Test")
            }
            ListItem {
                Label("Selected", systemImage: "checkmark")
            }
            ListItem {
                Label("Another, longer item", systemImage: "rectangle.and.pencil.and.ellipsis")
            }
        }
    }
}

extension Image {
    
    static let alert = Image.symbol("exclamationmark.triangle")
    static let checkmark = Image.symbol("checkmark")
    static let clear = Image.symbol("xmark.circle")
    static let dismiss = Image.symbol("xmark")
    static let text = Image.symbol("abc")
    static let type = Image.symbol("square.and.pencil")
    static let safari = Image.symbol("safari")
    static let settings = Image.symbol("gearshape")
    
    static func file(_ name: String) -> Image {
        Image(name)
    }
    
    static func symbol(_ name: String) -> Image {
        Image(systemName: name)
    }
}

public extension URL {
    
    static var keyboardSettings: URL? {
        URL(string: UIApplication.openSettingsURLString)
    }
}

public struct ListDisclosureIndicator: View {
    
    public init() {}
    
    public var body: some View {
        Image(systemName: "chevron.forward")
            .font(.footnote.bold())
            .foregroundColor(.secondary)
            .opacity(0.5)
    }
}

struct ListDisclosureIndicator_Previews: PreviewProvider {
    
    static var previews: some View {
        ListDisclosureIndicator()
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

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct ListNavigationLinkItem_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            List {
                ListNavigationLink(destination: Text("Page 1")) {
                    Text("Page 1")
                }
                ListNavigationLink(destination: Text("Page 2")) {
                    Label("Page 2", systemImage: "checkmark")
                }
                ListNavigationLink(destination: Text("Page 3")) {
                    Label("A long link to page 3", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
            }
        }
    }
}
