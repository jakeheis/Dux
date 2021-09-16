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
                .sherpa()
            NavigationLink(destination: DetailView()) {
                Text("Detail view")
                    .sherpa()
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

extension View {
    func sherpa() -> some View {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            [anchor]
        })
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
            .overlayPreferenceValue(SherpaPreferenceKey.self, { anchors in
                if anchors.count > 0 {
                    GeometryReader { proxy in
                        CutoutOverlay(cutouts: anchors.map { proxy[$0] })
                            .fill(Color.black.opacity(0.4), style: FillStyle(eoFill: true))
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            })
    }
    
//    @ViewBuilder
//    var overlay: some View {
//        Color.clear
//            .edgesIgnoringSafeArea(.all)
//            .onTapGesture { guide.show.toggle() }
//
//    }
}

struct CutoutOverlay: Shape {
    let cutouts: [CGRect]
    
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        for cutout in cutouts {
            path.addRect(cutout)
        }
        return path
    }
}

struct SherpaPreferenceKey: PreferenceKey {
    typealias Value = [Anchor<CGRect>]
    
    static var defaultValue: Value = []
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
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
