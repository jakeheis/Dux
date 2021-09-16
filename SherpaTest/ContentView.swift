//
//  ContentView.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/15/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SherpaView {
            TabView {
                NavigationView {
                    HomeView()
                }.tabItem { Label("Home", systemImage: "house") }
                Text("Hey").tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            NavigationLink(destination: DetailView()) {
                Text("Detail view")
            }
        }
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                sherpa.show = true
            }
        }
    }
}

struct SherpaView<Content: View>: View {
    @StateObject var guide = SherpaGuide()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(guide)
            .overlay(overlay)
    }
    
    @ViewBuilder
    var overlay: some View {
        if guide.show {
            Color.black
                .opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { guide.show.toggle() }
        } else {
            EmptyView()
        }
    }
}

class SherpaGuide: ObservableObject {
    @Published var show = false
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
