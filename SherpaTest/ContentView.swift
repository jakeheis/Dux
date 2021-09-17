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
                }
                .tabItem { Label("Home", systemImage: "house") }
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
//                .sherpa()
            NavigationLink(destination: DetailView()) {
                Text("Detail view")
                    .sherpa()
            }
            Button(action: {}) { Text("HEY") }
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
                    ZStack {
                        GeometryReader { proxy in
                            ForEach(overlayFrames(for: anchors.map { proxy[$0] }, screen: proxy.size)) { frame in
                                Color.black.opacity(0.4)
                                    .frame(width: frame.rect.width, height: frame.rect.height)
                                    .offset(x: frame.rect.minX, y: frame.rect.minY)
                            }
                        }
                    }.edgesIgnoringSafeArea(.all)
                }
            })
    }
    
    func overlayFrames(for rects: [CGRect], screen: CGSize) -> [OverlayFrame] {
//        var significantXCoordinates: Set<CGFloat> = []
//        var significantYCoordinates: Set<CGFloat> = []
//
//        for rect in rects {
//            significantXCoordinates.insert(rect.minX)
//            significantXCoordinates.insert(rect.maxX)
//            significantYCoordinates.insert(rect.minY)
//            significantYCoordinates.insert(rect.maxY)
//        }
//
//        let xs = significantXCoordinates.sorted()
//        let ys = significantYCoordinates.sorted()
//
//        var overlayRects: [CGRect] = []
//
//
//
//        return Color.clear
//            .edgesIgnoringSafeArea(.all)
//            .onTapGesture { guide.show.toggle() }
        
        let only = rects[0]
        return [
            .init(rect: .init(x: 0, y: 0, width: only.minX, height: screen.height)),
            .init(rect: .init(x: only.maxX, y: 0, width: screen.width - only.maxX, height: screen.height)),
            .init(rect: .init(x: only.minX, y: 0, width: only.width, height: only.minY)),
            .init(rect: .init(x: only.minX, y: only.maxY, width: only.width, height: screen.height - only.maxY))
        ]

        
//        Color.black.opacity(0.4)
//            .edgesIgnoringSafeArea(.all)
//            .onTapGesture(perform: { print("TAP before") })
//                            .mask(CutoutOverlay(proxy: proxy, anchors: anchors).fill(style: FillStyle(eoFill: true)))
//                            .clipShape(CutoutOverlay(proxy: proxy, anchors: anchors), style: FillStyle(eoFill: true))
//                            .contentShape(CutoutOverlay(proxy: proxy, anchors: anchors), eoFill: true)
    }
}

struct OverlayFrame: Identifiable {
    let rect: CGRect
    
    var id: String {
        rect.debugDescription
    }
}

struct Ten: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.midX - 10, y: rect.midY + 5, width: 20, height: 20))
    }
}

struct CutoutOverlay: Shape {
    let cutouts: [CGRect]
    
    init(proxy: GeometryProxy, anchors: [Anchor<CGRect>]) {
        cutouts = anchors.map { proxy[$0] }
    }
    
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
