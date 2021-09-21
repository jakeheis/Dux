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
                return .view(direction: .down, passthroughTouches: false) {
                    HStack {
                        Text("This takes you to a detail view")
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
    }
    
    @EnvironmentObject var sherpa: SherpaGuide
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            SherpaNavigationLink(destination: DetailView()) {
                Text("Detail view")
                    .sherpaMark(Plan.detailView)
            }
            Button(action: { sherpa.advance() }) { Text("HEY") }
                .sherpaMark(Plan.button)
        }
        .guide(isActive: true, plan: Plan.self)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
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
