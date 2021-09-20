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
//
//protocol PlanProvider {
//    associatedtype Plan where Plan: CaseIterable & RawRepresentable, Plan.RawValue == String
//}

extension View {
    func guide<Plan>(isActive: Bool, plan: Plan.Type) -> some View where Plan: CaseIterable & RawRepresentable, Plan.RawValue == String {
        GuidableView(isActive: isActive, plan: plan) {
            self
        }
    }
}

struct GuidableView<Content: View, Plan: CaseIterable & RawRepresentable>: View where Plan.RawValue == String {
    let isActive: Bool
    let content: Content
    
    @EnvironmentObject var sherpa: SherpaGuide
    
    var steps: [String] {
        Plan.allCases.map { $0.rawValue }
    }
    
    init(isActive: Bool, plan: Plan.Type, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.content = content()
    }
    
    var body: some View {
        content
            .onAppear {
                if isActive {
                    sherpa.start(plan: steps)
                }
            }
    }
}

struct SherpaNavigationLink<Destination: View, Label: View>: View {
    let destination: Destination
    let label: Label
    @State private var isActive = false
    
    @EnvironmentObject var sherpa: SherpaGuide
    
    init(destination: Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }

    var body: some View {
        ZStack {
            NavigationLink(destination: destination, isActive: $isActive, label: { Text("") })
            Button(action: tap) {
                label
            }
        }
    }
    
    func tap() {
        sherpa.stop()
        isActive.toggle()
    }
}

struct HomeView: View {
    enum Plan: String, CaseIterable {
        case button
        case detailView
    }
    
    @EnvironmentObject var sherpa: SherpaGuide
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            SherpaNavigationLink(destination: DetailView()) {
                Text("Detail view")
                    .sherpa(name: Plan.detailView)
            }
            Button(action: { sherpa.advance() }) { Text("HEY") }
                .sherpa(name: Plan.button)
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

extension View {
    func sherpa<T: RawRepresentable>(name: T) -> some View where T.RawValue == String {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            [name.rawValue: anchor]
        })
    }
}

struct SherpaContainerView<Content: View>: View {
    @StateObject var guide = SherpaGuide()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(guide)
            .overlayPreferenceValue(SherpaPreferenceKey.self, { anchors in
                if let active = guide.active, anchors[active] == nil {
                    failed(active: active)
                }
                if let active = guide.active, let anchor = anchors[active] {
                    ZStack {
                        GeometryReader { proxy in
                            ForEach(overlayFrames(for: proxy[anchor], screen: proxy.size)) { frame in
                                Color.black.opacity(0.4)
                                    .frame(width: frame.rect.width, height: frame.rect.height)
                                    .offset(x: frame.rect.minX, y: frame.rect.minY)
                            }
                        }
                    }.edgesIgnoringSafeArea(.all)
                }
            })
    }
    
    func failed(active: String) -> some View {
        assertionFailure("Could not find plan view: '\(active)'")
        return EmptyView()
    }
    
    func overlayFrames(for only: CGRect, screen: CGSize) -> [OverlayFrame] {
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
    typealias Value = [String: Anchor<CGRect>]
    
    static var defaultValue: Value = [:]
    
    static func reduce(value acc: inout Value, nextValue: () -> Value) {
        let newValue = nextValue()
        for (key, value) in newValue {
            acc[key] = value
        }
    }
}

class SherpaGuide: ObservableObject {
    @Published private(set) var active: String?
    
    private var currentPlan: [String]?
    
    func advance() {
        guard let active = active, let currentPlan = currentPlan else {
            return
        }
        guard let index = currentPlan.firstIndex(of: active), index + 1 < currentPlan.count else {
            return
        }
        
        withAnimation {
            self.active = currentPlan[index + 1]
        }
    }
    
    func start(plan: [String], after interval: TimeInterval = 0.5) {
        currentPlan = plan
        if plan.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                withAnimation {
                    self.active = plan[0]
                }
            }
        }
    }
    
    func stop() {
        currentPlan = nil
        active = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
