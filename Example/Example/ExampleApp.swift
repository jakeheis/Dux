//
//  ExampleApp.swift
//  Example
//
//  Created by Jake Heiser on 9/22/21.
//

import Dux
import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            DuxContainerView {
                DuxDemoList()
            }
        }
    }
}
