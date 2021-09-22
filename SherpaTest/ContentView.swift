//
//  ContentView.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/15/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }
            Text("Hey").tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}

struct HomeView: View {
    enum Plan: SherpaPlan {
        case button
        case detailView
        
        func config() -> CalloutConfig {
            switch self {
            case .button:
                return .text("Tap here!")
            case .detailView:
                return .view(direction: .down) {
                    HStack {
                        Text("This takes you to a detail view")
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
    }
    
    @EnvironmentObject var sherpa: SherpaGuide
    @State var detailLinkActive = false
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            NavigationLink(destination: DetailView(), isActive: $detailLinkActive) {
                Text("Detail view")
                    .sherpaMark(Plan.detailView, touchMode: .custom(detailViewSherpaTap))
            }
            Button(action: { sherpa.advance() }) { Text("HEY") }
                .sherpaMark(Plan.button, touchMode: .passthrough)
        }
        .guide(isActive: true, plan: Plan.self)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func detailViewSherpaTap() {
        sherpa.stop()
        detailLinkActive = true
    }
}

struct DetailView: View {
    @EnvironmentObject var sherpa: SherpaGuide
    
    var body: some View {
        VStack {
            Text("Details")
        }
    }
}
