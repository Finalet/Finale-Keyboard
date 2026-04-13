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
                SwipeGestureRow(.right(), "Insert space or punctuation")
                SwipeGestureRow(.vertical(), "Cycle through suggestions")
                SwipeGestureRow(.left(), "Delete word")
                SwipeGestureRow(.left("on backspace"), "Open emojis")
                SwipeGestureRow(.right("on shift"), "Toggle symbols")
                SwipeGestureRow(.up("on backspace"), "Return")
            }
            Section (header: Text("Shortcuts")) { 
                SwipeGestureRow(.down("on shortcut key"), "Use shortcut")
                SwipeGestureRow(.hold("backspace"), "Peak shortcuts")
            }
            Section (header: Text("Miscellaneous")) {
                SwipeGestureRow(.up("on shift"), "Change language")
                SwipeGestureRow(.hold("shift"), "Toggle autocorrect")
                SwipeGestureRow(.up("and hold"), "Continously type character")
            }
        }
        .navigationTitle(Localize.gesturesGuideRow)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                TextField(Localize.inputFieldPlaceholder, text: $tryText)
                    .fontWeight(.regular)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct SwipeGestureRow: View {
    let direction: SwipeDirection
    let label: String
    
    init(_ direction: SwipeDirection, _ label: String) {
        self.direction = direction
        self.label = label
    }

    var body: some View {
        NavigationLink(destination: {}) {
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


#Preview {
    GesturesGuideView()
}
