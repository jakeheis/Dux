//
//  DuxTestApp.swift
//  DuxTest
//
//  Created by Jake Heiser on 9/15/21.
//

import SwiftUI

@main
struct DuxTestApp: App {
    var body: some Scene {
        WindowGroup {
            DuxContainerView(accessory: SkipButton()) {
                ContentView()
            }
        }
    }
}
