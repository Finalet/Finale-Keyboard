//
//  GesturesGuideView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/13/26.
//

import Foundation
import SwiftUI

private let allGestures: [GestureGroup] = [
    GestureGroup(name: "Essential", gestures: [
        GestureExplanation("Insert space and autocorrect word", .right(), "insert-space"),
        GestureExplanation("Insert punctuation", .right("after space"), "insert-punctuation"),
        GestureExplanation("Cycle through suggestions", .vertical(), "cycle-suggestions"),
        GestureExplanation("Delete a word", .left(), "delete-word"),
        GestureExplanation("Toggle symbols", .right("on 'shift'"), "toggle-symbols"),
        GestureExplanation("Open emojis", .left("on 'backspace'"), "open-emojis"),
        GestureExplanation("Return", .up("on 'backspace'"), "return"),
    ]),
    GestureGroup(name: "Shortcuts", gestures: [
        GestureExplanation("Use a shortcut", .down("on shortcut key"), "use-shortcut"),
        GestureExplanation("Peak shortcuts", .hold("'backspace'"), "peak-shortcuts"),
    ]),
    GestureGroup(name: "Miscellaneous", gestures: [
        GestureExplanation("Change language", .up("on shift"), "change-language"),
        GestureExplanation("Learn new word", .up(), "learn-word"),
        GestureExplanation("Toggle autocorrect", .hold("'shift'"), "toggle-autocorrect"),
        GestureExplanation("Move cursor", .hold("and slide anywhere"), "move-cursor"),
        GestureExplanation("Continously type character", .up("and hold"), "continuesly-type"),
    ])
]

struct GesturesGuideView: View {
    typealias Localize = Localization.HomeScreen
        
    var body: some View {
        List {
            ForEach(allGestures) { group in
                Section(header: Text(group.name)) {
                    ForEach(group.gestures) { gesture in
                        SwipeGestureRow(gesture.swipeGesture, gesture.gestureActionLabel) {
                            GesturesDetailedView(index: gestureGlobalIndex(for: gesture.gestureActionLabel))
                        }
                    }
                }
            }
        }
        .navigationTitle(Localize.gesturesGuideRow)
        .toolbar {
            ToolbarInputField()
        }
    }
    
    private func gestureGlobalIndex(for gestureActionLabel: String) -> Int {
        allGestures
            .flatMap(\.gestures)
            .firstIndex(where: { $0.gestureActionLabel == gestureActionLabel }) ?? 0
    }
}

struct SwipeGestureRow<Destination>: View where Destination: View {
    let direction: SwipeDirection
    let label: String
    let destination: () -> Destination
    
    init(_ direction: SwipeDirection, _ label: String, @ViewBuilder _ destination: @escaping () -> Destination) {
        self.direction = direction
        self.label = label
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: { destination() }) {
            VStack (alignment: .leading, spacing: 10) {
                Text(label)
                SwipeGestureView(direction)
            }
        }
    }
}

struct SwipeGestureView: View {
    let direction: SwipeDirection
    
    init(_ direction: SwipeDirection) {
        self.direction = direction
    }
    
    @Environment(\.colorScheme) private var colorScheme
    var dark: Bool { return colorScheme == .dark }
    
    var body: some View {
        Text("\(direction.label) \(direction.icon)")
            .font(.monospaced(.system(size: 12, weight: .medium))())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.brand.mix(with: dark ? Color.black : Color.white, by: dark ? 0.7 : 0.8))
                        .stroke(Color.brand.mix(with: dark ? Color.black : Color.white, by: dark ? 0.5 : 0.6), lineWidth: 1)
                        .shadow(color: Color.brand.opacity(0.2), radius: dark ? 1 : 2, y: 1)
                }
            )
            .foregroundStyle(Color.brand)
    }
}

struct GesturesDetailedView: View {
    @State var index: Int
    @State var tryText: String = ""
    
    var gestures: [GestureExplanation] { allGestures.flatMap(\.gestures) }
    var currentGesture: GestureExplanation { gestures[index] }
    
    typealias Localize = Localization.HomeScreen
    
    var body: some View {
        VStack {
            ZStack {
                TabView(selection: $index) {
                    ForEach(0..<gestures.count, id: \.self) { i in
                        VStack {
                            Image(gestures[i].imageName)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .tag(i)
                            
                            Text("\(currentGesture.swipeGesture.label.firstUppercased) to \(currentGesture.gestureActionLabel.lowercased())")
                                .multilineTextAlignment(.center)
                                .fontWeight(.semibold)
                                .font(.title2)
                                .foregroundStyle(Color.brand)
                                .shadow(color: Color.brand.opacity(0.25), radius: 2, y: 2)
                                .padding(.horizontal, 16)
                            
                            Spacer()
                        }
                        .offset(y: -80)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                VStack {
                    LinearGradient(colors: [Color(uiColor: .secondarySystemBackground), Color.clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 10)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            Spacer()
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .toolbarBackground(.foreground, for: .bottomBar)
        .navigationTitle(currentGesture.gestureActionLabel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarInputField()
        }
    }
}

struct GestureGroup: Identifiable {
    var id: String { name }
    
    let name: String
    let gestures: [GestureExplanation]
}

struct GestureExplanation: Identifiable {
    var id: String { gestureActionLabel }
    
    init(_ gestureActionLabel: String, _ swipeGesture: SwipeDirection, _ imageName: String) {
        self.gestureActionLabel = gestureActionLabel
        self.swipeGesture = swipeGesture
        self.imageName = imageName
    }
    
    let gestureActionLabel: String
    let swipeGesture: SwipeDirection
    let imageName: String
}

enum SwipeDirection {
    case up(String = "")
    case right(String = "")
    case down(String = "")
    case left(String = "")
    case vertical(String = "")
    case hold(String = "")
    
    var icon: String {
        switch (self) {
            case .up(_): return "↑"
            case .right(_): return "→"
            case .down(_): return "↓"
            case .left(_): return "←"
            case .vertical(_): return "⇅"
            case .hold(_): return "⦿"
        }
    }
    
    var label: String {
        switch (self) {
            case .up(let label): return "swipe up\(!label.isEmpty ? " \(label)" : "")"
            case .right(let label): return "swipe right\(!label.isEmpty ? " \(label)" : "")"
            case .down(let label): return "swipe down\(!label.isEmpty ? " \(label)" : "")"
            case .left(let label): return "swipe left\(!label.isEmpty ? " \(label)" : "")"
            case .vertical(let label): return "swipe up or down\(!label.isEmpty ? " \(label)" : "")"
            case .hold(let label): return "hold\(!label.isEmpty ? " \(label)" : "")"
        }
    }
}

#Preview {
    NavigationStack {
        GesturesGuideView()
    }
}
