//
//  SherpaTestApp.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/15/21.
//

import SwiftUI

@main
struct SherpaTestApp: App {
    var body: some Scene {
        WindowGroup {
            SherpaContainerView(overlay: EndDemo()) {
                DemoListView()
            }
        }
    }
}

struct EndDemo: View {
    @EnvironmentObject var sherpa: SherpaGuide
    
    var body: some View {
        Button(action: quit) {
            Text("Quit")
                .padding(10)
                .background(Capsule().fill(Color.white))
        }
        .padding(.top, 40)
        .padding(.trailing, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    func quit() {
        withAnimation {
            sherpa.stop()
        }
    }
}
