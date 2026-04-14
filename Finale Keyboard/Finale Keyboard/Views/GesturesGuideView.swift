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
        GestureExplanation("Insert space or punctuation", .right(), "Swipe right"),
        GestureExplanation("Cycle through suggestions", .vertical(), "Swipe right"),
        GestureExplanation("Delete word", .left(), "Swipe right"),
        GestureExplanation("Open emojis", .left("on backspace"), "Swipe right"),
        GestureExplanation("Toggle symbols", .right("on shift"), "Swipe right"),
        GestureExplanation("Return", .up("on backspace"), "Swipe right"),
    ]),
    GestureGroup(name: "Shortcuts", gestures: [
        GestureExplanation("Use shortcut", .down("on shortcut key"), "Swipe right"),
        GestureExplanation("Peak shortcuts", .hold("backspace"), "Swipe right"),
    ]),
    GestureGroup(name: "Miscellaneous", gestures: [
        GestureExplanation("Change language", .up("on shift"), "Swipe right"),
        GestureExplanation("Learn new word", .up("when new word"), "Swipe right"),
        GestureExplanation("Toggle autocorrect", .hold("shift"), "Swipe right"),
        GestureExplanation("Continously type character", .up("and hold"), "Swipe right"),
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
    
    var body: some View {
        Text(direction.label)
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

struct GesturesDetailedView: View {
    @State var index: Int
    @State var tryText: String = ""
    
    var gestures: [GestureExplanation] { allGestures.flatMap(\.gestures) }
    var currentGesture: GestureExplanation { gestures[index] }
    
    typealias Localize = Localization.HomeScreen
    
    var body: some View {
        VStack () {
            TabView(selection: $index) {
                ForEach(0..<gestures.count, id: \.self) { i in
                    VStack {
                        Image(gestures[i].imageName).resizable().tag(i)
                        SwipeGestureView(gestures[i].swipeGesture)
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Spacer()
        }
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
    
    var label: String {
        switch (self) {
            case .up(let label): return "swipe up\(!label.isEmpty ? " \(label)" : "")  ↑"
            case .right(let label): return "swipe right\(!label.isEmpty ? " \(label)" : "")  →"
            case .down(let label): return "swipe down\(!label.isEmpty ? " \(label)" : "")  ↓"
            case .left(let label): return "swipe left\(!label.isEmpty ? " \(label)" : "")  ←"
            case .vertical(let label): return "swipe up or down\(!label.isEmpty ? " \(label)" : "")  ⇅"
            case .hold(let label): return "hold\(!label.isEmpty ? " \(label)" : "")  ⦿"
        }
    }
}

#Preview {
    GesturesGuideView()
}
