//
//  MoreView.swift
//  Finale Keyboard
//
//  Created by Grant Oganan on 7/19/22.
//

import Foundation
import SwiftUI

struct MoreView: View {
    
    var body: some View {
        List {
            ListNavigationButton(action: { UIApplication.shared.open(URL(string: "https://apps.apple.com/app/apple-store/id1622931101")!) } ) {
                Image("Finale To Do Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 36)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                Text("Finale To Do: Task Manager")
                
            }
            ListNavigationButton(action: { UIApplication.shared.open(URL(string: "https://apps.apple.com/app/apple-store/id1546661013")!) } ) {
                Image("Finale Habits Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 36)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                Text("Finale Habits: Daily Tracker")
            }
        }
    }
}
