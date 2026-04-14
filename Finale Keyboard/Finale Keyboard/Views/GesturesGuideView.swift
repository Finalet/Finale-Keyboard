//
//  GesturesGuideView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/13/26.
//

import Foundation
import SwiftUI

struct GesturesGuideView: View {
    typealias Localize = Localization.HomeScreen
        
    @State var tryText: String = ""
    
    var body: some View {
        List {
            Section (header: Text("Essential")) {
                SwipeGestureRow(.right(), "Insert space or punctuation") { GesturesDetailedView(index: 0) }
                SwipeGestureRow(.vertical(), "Cycle through suggestions")  { GesturesDetailedView(index: 1) }
                SwipeGestureRow(.left(), "Delete word")  { GesturesDetailedView(index: 2) }
                SwipeGestureRow(.left("on backspace"), "Open emojis")  { GesturesDetailedView(index: 3) }
                SwipeGestureRow(.right("on shift"), "Toggle symbols")  { GesturesDetailedView(index: 4) }
                SwipeGestureRow(.up("on backspace"), "Return")  { GesturesDetailedView(index: 5) }
            }
            Section (header: Text("Shortcuts")) { 
                SwipeGestureRow(.down("on shortcut key"), "Use shortcut")  { GesturesDetailedView(index: 6) }
                SwipeGestureRow(.hold("backspace"), "Peak shortcuts")  { GesturesDetailedView(index: 7) }
            }
            Section (header: Text("Miscellaneous")) {
                SwipeGestureRow(.up("on shift"), "Change language")  { GesturesDetailedView(index: 8) }
                SwipeGestureRow(.hold("shift"), "Toggle autocorrect")  { GesturesDetailedView(index: 9) }
                SwipeGestureRow(.up("and hold"), "Continously type character")  { GesturesDetailedView(index: 10) }
            }
        }
        .navigationTitle(Localize.gesturesGuideRow)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                TextField(Localize.inputFieldPlaceholder, text: $tryText)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
            }
        }
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

struct GesturesDetailedView: View {
    @State var index: Int
    @State var tryText: String = ""
    @FocusState private var isInputFocused: Bool
    
    let images = ["Swipe right", "Swipe right punctuation", "Swipe up down", "Swipe left", "Emoji", "Symbols", "Languages", "Return", "Learn", "Move cursor", "Toggle autocorrect"]
    
    typealias Localize = Localization.HomeScreen
    
    var body: some View {
        VStack (alignment: .leading) {
            TabView(selection: $index) {
                ForEach(0..<images.count, id: \.self) {
                    Image(self.images[$0]).resizable().tag($0)
                }
            }
            .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                TextField(Localize.inputFieldPlaceholder, text: $tryText)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    GesturesGuideView()
}
