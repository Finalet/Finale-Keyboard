//
//  SpacebarLootboxView.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/10/26.
//

import Foundation
import SwiftUI

struct SpacebarLootboxView: View {
    let cellSize: CGFloat = 72
    let spacing: CGFloat = 16
    let spinDuration = 10.0
    let nItems = 50
    let winProbability = 0.1
    
    @State var items: [Bool] = []

    @State var spinWidth: Double?
    @State var offset: CGFloat = 0
    @State private var lastCenteredCellIndex: Int?

    private let spinHaptics = UIImpactFeedbackGenerator(style: .medium)

    var targetIndex: Int { max(items.count - 5, 0) }
    
    @State var landed = false
    var didWin: Bool { items[targetIndex] == true }
    
    @State var showTitle = false
    @State var showBottomButton = false
    
    @EnvironmentObject var iapManager: InAppPurchasesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            if showTitle {
                VStack {
                    HStack {
                        Text(didWin ? "Congrats, you got your spacebar" : "Sorry")
                            .font(.system(size: 32, weight: .semibold))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 64)
                    .padding(.horizontal, 16)
                    Spacer()
                }
            }
            VStack {
                GeometryReader { geometry in
                    VStack {
                        HStack(spacing: spacing) {
                            ForEach(items.indices, id: \.self) { index in
                                LootboxCell(isSpacebar: items[index], isTarget: landed && index == targetIndex, cellSize: cellSize)
                            }
                        }
                        .offset(x: offset)
                        .modifier(AnimatableOffsetObserver(value: offset, onChange: handleOffsetChange))
                        .padding(.vertical, spacing * 2)
                        .border(width: 1, edges: [.top, .bottom], color: Color(uiColor: .systemGray4))
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
                    .onAppear {
                        spinWidth = geometry.size.width
                        Start()
                    }
                }
            }
            .frame(height: cellSize + spacing * 4)
            .overlay(TargetCellHighlight(landed: landed))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            if showBottomButton {
                VStack {
                    Spacer()
                    HStack {
                        VStack (spacing: 16) {
                            DefaultButton(label: didWin ? "Redeem prize" : "I want to try again.") {
                                if didWin {
                                    dismiss()
                                } else {
                                    Task { await iapManager.PurchaseSpacebarGamble(onSuccess: { Start() }) }
                                }
                            }
                            if !didWin {
                                OutlineButton(label: "I give up, like I always do.") { dismiss() }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    func GenerateItems () {
        items = (0..<nItems).map { i in Double.random(in: 0..<1) < winProbability }
        for i in (targetIndex - 3)...(targetIndex + 3) {
            if i == targetIndex { continue }
            items[i] = Double.random(in: 0..<1) < winProbability * 2
        }
    }
    
    func Start() {
        GenerateItems()
        spinHaptics.prepare()
        lastCenteredCellIndex = nil

        withAnimation {
            landed = false
            showTitle = false
            showBottomButton = false
        }
        
        guard let spinWidth = spinWidth, spinWidth > 0, nItems > 0 else { return }

        let center = CGFloat(targetIndex) * (cellSize + spacing) + cellSize / 2
        let end = spinWidth / 2 - center

        offset = spinWidth + cellSize

        DispatchQueue.main.async {
            withAnimation(.timingCurve(0.25, 1, 0.36, 1, duration: spinDuration)) {
                offset = end
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) {
            withAnimation { landed = true }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration + 1.0) { withAnimation{ showTitle = true } }
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration + 2.0) { withAnimation{ showBottomButton = true } }
    }

    func handleOffsetChange(_ currentOffset: CGFloat) {
        guard let spinWidth else { return }

        let rawIndex = (spinWidth / 2 - currentOffset - cellSize / 2) / (cellSize + spacing)
        let centeredIndex = Int(rawIndex.rounded())

        guard items.indices.contains(centeredIndex), centeredIndex != lastCenteredCellIndex else { return }

        lastCenteredCellIndex = centeredIndex
        spinHaptics.impactOccurred()
        spinHaptics.prepare()
    }
}

private struct AnimatableOffsetObserver: AnimatableModifier {
    var value: CGFloat
    let onChange: (CGFloat) -> Void

    var animatableData: CGFloat {
        get { value }
        set {
            value = newValue
            let callback = onChange
            DispatchQueue.main.async {
                callback(newValue)
            }
        }
    }

    func body(content: Content) -> some View {
        content
    }
}

private struct LootboxCell: View {
    let isSpacebar: Bool
    let isTarget: Bool
    let cellSize: CGFloat

    @State private var showPrize = false

    var body: some View {
        let cornerRadius: CGFloat = 18

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isTarget ? Color.brand.opacity(0.16) : Color(uiColor: .systemBackground))
                .stroke(isTarget ? Color.brand : Color(uiColor: .systemGray4), lineWidth: isTarget ? 3 : 1)
                .frame(width: cellSize, height: cellSize)

            Group {
                if isSpacebar {
                    Spacebar(glow: showPrize)
                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                        .scaleEffect(cellSize * 0.8 / 200)
                        .rotationEffect(.degrees(showPrize ? 0 : -45))
                } else {
                    Text("🖕")
                        .font(.system(size: 34))
                }
            }
            .offset(y: showPrize ? -60 : 0)
            .scaleEffect(showPrize ? 3 : 1)
        }
        .onChange(of: isTarget) { _, isTarget in
            if isTarget {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation { self.showPrize = true }
                }
            } else {
                self.showPrize = false
            }
        }
    }
}

struct TargetCellHighlight: View {
    let landed: Bool
    var body: some View {
        HStack {
            Spacer()
            VStack{
                Rectangle()
                    .fill(landed ? Color.brand : Color(uiColor: .systemGray4))
                    .frame(width: 2, height: 20)
                Spacer()
                Rectangle()
                    .fill(landed ? Color.brand : Color(uiColor: .systemGray4))
                    .frame(width: 2, height: 20)
            }
            Spacer()
        }
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}


extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
    
}

#Preview {
    SpacebarLootboxView()
}
