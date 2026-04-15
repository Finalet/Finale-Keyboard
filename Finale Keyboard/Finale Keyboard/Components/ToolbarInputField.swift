//
//  ToolbarInputField.swift
//  Finale Keyboard
//
//  Created by Grant Oganyan on 4/14/26.
//

import Foundation
import SwiftUI

struct ToolbarInputField: ToolbarContent {
    @State var text: String = ""
    @State var isFocused: Bool = false
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            ToolbarTextFieldView(text: $text, isFocused: $isFocused)
                .padding(.horizontal, 16)
        }
        if isFocused {
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    isFocused = false
                } label: {
                    Image(systemName: "xmark")
                }
                .tint(.primary)
            }
        }
    }
}

struct ToolbarTextFieldView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ToolbarTextFieldView

        init(_ parent: ToolbarTextFieldView) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            withAnimation { parent.isFocused = true }
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            withAnimation { parent.isFocused = false }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = Localization.HomeScreen.inputFieldPlaceholder
        return textField
    }

    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text

        Task { @MainActor in
            try? Task.checkCancellation()
            if isFocused { uiView.becomeFirstResponder() }
            else { uiView.resignFirstResponder() }
        }
         
    }
}
