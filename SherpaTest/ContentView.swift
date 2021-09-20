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
    func guide<Plan>(isActive: Bool, plan: Plan.Type) -> some View where Plan: SherpaPlan {
        GuidableView(isActive: isActive, plan: plan) {
            self
        }
    }
}

struct GuidableView<Content: View, Plan: SherpaPlan>: View {
    let isActive: Bool
    let content: Content
    
    @EnvironmentObject private var sherpa: SherpaGuide
    
    init(isActive: Bool, plan: Plan.Type, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.content = content()
//        self.steps = Plan.allCases.map { $0.rawValue }
    }
    
    var body: some View {
        content
            .onAppear {
                if isActive {
                    sherpa.start(plan: Plan.allCases.map { $0.rawValue })
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
        withAnimation {
            sherpa.stop()
        }
        isActive.toggle()
    }
}

struct SherpaMark {
    let key: String
    let content: AnyView
}

protocol SherpaPlan: RawRepresentable, CaseIterable where RawValue == String {
//    associatedtype Mark: View
    
//    func mark() -> SherpaMark
}

struct HomeView: View {
    enum Plan: String, SherpaPlan {
        case button
        case detailView
//
//        func mark() -> SherpaMark {
//            switch self {
//            case .button:
//                return .init(key: Self.button.rawValue, content: <#T##AnyView#>)
//                Text("Tap here!")
//            case .detailView:
//                Text("This will take you to detail view")
//            }
//        }
    }
    
    @EnvironmentObject var sherpa: SherpaGuide
    
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            SherpaNavigationLink(destination: DetailView()) {
                Text("Detail view")
                    .sherpa(name: Plan.detailView, mark: HStack {
                        Text("This takes you to a detail view")
                        Image(systemName: "chevron.right")
                    })
            }
            Button(action: { sherpa.advance() }) { Text("HEY") }
                .sherpa(name: Plan.button, text: "Tap here!")
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

struct SherpaConfig {
    let anchor: Anchor<CGRect>
    let text: AnyView
}

extension View {
    func sherpa<T: RawRepresentable>(name: T, text: String) -> some View where T.RawValue == String {
        sherpa(name: name, mark: Text(text))
    }
    
    func sherpa<T: RawRepresentable, Mark: View>(name: T, mark: Mark) -> some View where T.RawValue == String {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            [name.rawValue: SherpaConfig(anchor: anchor, text: AnyView(mark))]
        })
    }
}

struct SherpaContainerView<Content: View>: View {
    @StateObject var guide = SherpaGuide()
    let content: Content
    
    @State private var popoverSize: CGSize = .zero
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environmentObject(guide)
            .overlayPreferenceValue(SherpaPreferenceKey.self, { anchors in
                switch guide.state {
                case .hidden: EmptyView()
                case .transition:
                    ZStack {
                        Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                        if let current = guide.current, let config = anchors[current] {
                            Popover(config: config).opacity(0)
                        }
                    }
                case .active:
                    if let current = guide.current, let config = anchors[current] {
                        ZStack {
                            GeometryReader { proxy in
                                ForEach(overlayFrames(for: proxy[config.anchor], screen: proxy.size)) { frame in
                                    Color.black.opacity(0.4)
                                        .frame(width: frame.rect.width, height: frame.rect.height)
                                        .offset(x: frame.rect.minX, y: frame.rect.minY)
                                }
                                
                                Popover(config: config)
                                    .offset(x: proxy[config.anchor].midX - popoverSize.width / 2, y: proxy[config.anchor].minY - popoverSize.height)
                            }
                        }.edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                guide.hide()
                            }
                        }
                    } else {
                        failed(active: guide.current)
                    }
                }
            })
            .onPreferenceChange(PopoverPreferenceKey.self, perform: { popoverSize = $0 })
    }
    
    func failed(active: String?) -> some View {
        assertionFailure("Could not find plan view: '\(active ?? "<nil>")'")
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

struct Popover: View {
    let config: SherpaConfig
    
    var body: some View {
        VStack(spacing: 0) {
            PopoverContent(config: config)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white))
            Image(systemName: "triangle.fill")
                .resizable().aspectRatio(contentMode: .fit)
                .foregroundColor(Color.white)
                .rotationEffect(.degrees(180))
                .frame(width: 15)
                .offset(y: -3)
        }
        .overlay(GeometryReader { proxy in
            Color.clear
                .preference(key: PopoverPreferenceKey.self, value: proxy.size)
        })
    }
}

struct PopoverContent: View {
    let config: SherpaConfig
    
    var body: some View {
        config.text
            .padding(6)
    }
}

struct PopoverPreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: Value = .zero
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
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
    typealias Value = [String: SherpaConfig]
    
    static var defaultValue: Value = [:]
    
    static func reduce(value acc: inout Value, nextValue: () -> Value) {
        let newValue = nextValue()
        for (key, value) in newValue {
            acc[key] = value
        }
    }
}

class SherpaGuide: ObservableObject {
    enum State {
        case hidden
        case transition
        case active
    }
    
    @Published private(set) var state: State = .hidden
    private(set) var current: String? = nil

    private var currentPlan: [String]?
    
    func advance() {
        guard let current = current, let currentPlan = currentPlan else {
            return
        }
        guard let index = currentPlan.firstIndex(of: current), index + 1 < currentPlan.count else {
            return
        }
        
        self.current = currentPlan[index + 1]
        
        withAnimation {
            if state == .active {
                self.state = .transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.state = .active
                    }
                }
            } else {
                self.state = .active
            }
        }
    }
    
    func start(plan: [String], after interval: TimeInterval = 0.5) {
        currentPlan = plan
        if plan.count > 0 {
            current = plan[0]
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                withAnimation {
                    self.state = .active
                }
            }
        }
    }
    
    func hide() {
        state = .hidden
    }
    
    func stop() {
        currentPlan = nil
        current = nil
        state = .hidden
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
