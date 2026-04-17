//
//  DefaultButton.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/12/26.
//

import Foundation
import SwiftUI

struct DefaultButton<Label: View>: View {
    let style: DefaultButtonStyle
    let action: () -> Void
    let disabled: Bool
    let label: () -> Label

    init(_ style: DefaultButtonStyle = .primary, disabled: Bool = false, @ViewBuilder label: @escaping () -> Label, action: @escaping () -> Void = {}) {
        self.style = style
        self.action = action
        self.disabled = disabled
        self.label = label
    }

    @Environment(\.colorScheme) private var colorScheme
    var dark: Bool { return colorScheme == .dark }
    
    var fillColor: Color {
        switch style {
        case .primary:
            return Color.brand
        case .outline:
            return Color(uiColor: .systemGray6)
        }
    }

    var shadow: ColorConfig {
      switch style {
      case .primary:
          return ColorConfig(color: Color.brand.opacity(0.5), radius: 5, y: 5)
      case .outline:
          return ColorConfig(color: Color.black.opacity(dark ? 0.5 : 0.1), radius: 2, y: 3)
      }
    }

    var innerShadowColor: Color {
        switch style {
        case .primary:
            return .white.opacity(0.25)
        case .outline:
            return .white.opacity(dark ? 0.2 : 0.5)
        }
    }

    var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .outline:
            return Color.primary
        }
    }


    var body: some View {
        Button(action: action) {
            VStack {
                label()
            }
            .frame(maxWidth: .infinity)
            .font(.headline)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(fillColor.shadow(.inner(color: innerShadowColor, radius: 1, y: 3)))
                    .stroke(Color(uiColor: .systemGray3), lineWidth: dark || style == .primary ? 0 : 1)
            )
            .foregroundStyle(foregroundColor)
            .cornerRadius(12)
            .shadow(color: disabled ? .clear : shadow.color, radius: shadow.radius, y: shadow.y)
            .opacity(disabled ? 0.5 : 1)
        }
        .disabled(disabled)
    }
}

enum DefaultButtonStyle {
    case primary
    case outline
}

struct ColorConfig {
  let color: Color
  let radius: CGFloat
  let y: CGFloat
}
