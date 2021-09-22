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
    enum Tags: SherpaTags {
        case button
        case detailView
        
        func createCallout() -> Callout {
            switch self {
            case .button:
                return .text("Tap here!")
            case .detailView:
                return .view(edge: .bottom) {
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
                    .sherpaTag(Tags.detailView, touchMode: .passthrough)
            }
            Button(action: { sherpa.advance() }) { Text("HEY") }
                .sherpaTag(Tags.button, touchMode: .passthrough)
        }
        .guide(isActive: true, tags: Tags.self)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .stopSherpa(sherpa, onLink: detailLinkActive)
    }
}

struct DetailView: View {
    @EnvironmentObject var sherpa: SherpaGuide
    
    enum Tags: SherpaTags {
        case details
        
        func createCallout() -> Callout {
            .text("Some details")
        }
    }
    
    var body: some View {
        VStack {
            Text("Details")
                .sherpaTag(Tags.details)
        }
        .guide(isActive: true, tags: Tags.self)
    }
}
