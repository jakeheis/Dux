//
//  ContentView.swift
//  DuxTest
//
//  Created by Jake Heiser on 9/15/21.
//

import SwiftUI

struct DuxDemoList: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: BasicDemo()) {
                    Text("Basic")
                }
                NavigationLink(destination: BarDemo()) {
                    Text("Bars")
                }
                NavigationLink(destination: CustomDemo()) {
                    Text("Custom")
                }
                NavigationLink(destination: ManualDemo()) {
                    Text("Manual flow control")
                }
            }
            .navigationTitle("Dux Demos")
        }
    }
}
