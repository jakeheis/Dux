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
                    sherpa.start(plan: Array(Plan.allCases))
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

protocol SherpaPlanItem {
    func config() -> CalloutConfig
    
    func onExplanationTap(sherpa: SherpaGuide)
    func onBackgroundTap(sherpa: SherpaGuide)
}

extension SherpaPlanItem {
    func key() -> String {
        String(reflecting: Self.self) + "." + String(describing: self)
    }
    
    func onExplanationTap(sherpa: SherpaGuide) {
        sherpa.advance()
    }
    
    func onBackgroundTap(sherpa: SherpaGuide) {
        sherpa.advance()
    }
}

protocol SherpaPlan: CaseIterable, SherpaPlanItem {
//    associatedtype Mark: View
    
//    func mark() -> SherpaMark
    
    func config() -> CalloutConfig
}

struct CalloutConfig {
    enum Direction {
        case up
        case down
    }
    
    static func text(_ text: String, direction: Direction = .up) -> Self {
        .view(direction: direction) { Text(text) }
    }
    
    static func view<V: View>(direction: Direction = .up, @ViewBuilder content: () -> V) -> Self {
        let view = content().padding(6).background(RoundedRectangle(cornerRadius: 5).fill(Color.white))
        return .init(body: AnyView(view), direction: direction)
    }
    
    let body: AnyView
    let direction: Direction
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

struct SherpaDetails {
    let anchor: Anchor<CGRect>
    let config: CalloutConfig
}

extension View {
    func sherpaMark<T: SherpaPlan>(_ name: T) -> some View {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            return [name.key(): SherpaDetails(anchor: anchor, config: name.config())]
        })
    }
}

extension SherpaContainerView where Overlay == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.init(overlay: EmptyView(), content: content)
    }
}

struct SherpaContainerView<Overlay: View, Content: View>: View {
    @StateObject private var guide = SherpaGuide()
    
    let content: Content
    let overlay: Overlay
    
    @State private var popoverSize: CGSize = .zero
    
    init(overlay: Overlay, @ViewBuilder content: () -> Content) {
        self.overlay = overlay
        self.content = content()
    }
    
    func currentDetails(from all: SherpaPreferenceKey.Value) -> SherpaDetails? {
        if let current = guide.current, let details = all[current.key()] {
            return details
        } else {
            return nil
        }
    }
    
    var body: some View {
        content
            .environmentObject(guide)
            .overlayPreferenceValue(SherpaPreferenceKey.self, { all in
                ZStack {
                    if guide.state == .transition {
                        Color.black.opacity(0.4)
                        if let details = currentDetails(from: all) {
                            Popover(config: details.config).opacity(0)
                        }
                    } else if guide.state == .active {
                        if let current = guide.current, let details = currentDetails(from: all) {
                            GeometryReader { proxy in
                                ForEach(overlayFrames(for: proxy[details.anchor], screen: proxy.size)) { frame in
                                    Color.black.opacity(0.4)
                                        .frame(width: frame.rect.width, height: frame.rect.height)
                                        .offset(x: frame.rect.minX, y: frame.rect.minY)
                                }
                                .onTapGesture {
                                    current.onBackgroundTap(sherpa: guide)
                                }
                                
                                Popover(config: details.config)
                                    .offset(
                                        x: proxy[details.anchor].midX - popoverSize.width / 2,
                                        y: details.config.direction == .up ? proxy[details.anchor].minY - popoverSize.height : proxy[details.anchor].maxY
                                    )
                                    .onTapGesture {
                                        current.onExplanationTap(sherpa: guide)
                                    }
                                overlay.environmentObject(guide)
                            }
                        } else {
                            failed(active: guide.current?.key())
                        }
                    }
                    overlay.environmentObject(guide).opacity(guide.state != .hidden ? 0.4 : 0)
                }.edgesIgnoringSafeArea(.all)
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
    let config: CalloutConfig
    
    var body: some View {
        VStack(spacing: 0) {
            if config.direction == .down {
                arrow()
                    .offset(y: 3)
            }
            config.body
            if config.direction == .up {
                arrow()
                    .rotationEffect(.degrees(180))
                    .offset(y: -3)
            }
        }
        .overlay(GeometryReader { proxy in
            Color.clear
                .preference(key: PopoverPreferenceKey.self, value: proxy.size)
        })
    }
    
    func arrow() -> some View {
        Image(systemName: "triangle.fill")
            .resizable().aspectRatio(contentMode: .fit)
            .foregroundColor(Color.white)
            .frame(width: 15)
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
    typealias Value = [String: SherpaDetails]
    
    static var defaultValue: Value = [:]
    
    static func reduce(value acc: inout Value, nextValue: () -> Value) {
        let newValue = nextValue()
        for (key, value) in newValue {
            acc[key] = value
        }
    }
}

final class SherpaGuide: ObservableObject {
    enum State {
        case hidden
        case transition
        case active
    }
    
    @Published private(set) var state: State = .hidden
    private(set) var current: SherpaPlanItem? = nil

    private var currentPlan: [SherpaPlanItem]?
    
    func advance() {
        guard let current = current, let currentPlan = currentPlan else {
            return
        }
        guard let index = currentPlan.firstIndex(where: { $0.key() == current.key() }) else {
            return
        }
        
        guard index + 1 < currentPlan.count else {
            stop()
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
    
    func start(plan: [SherpaPlanItem], after interval: TimeInterval = 0.5) {
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
    
    func stop(animated: Bool = true) {
        if animated {
            withAnimation {
                stopImpl()
            }
        } else {
            stopImpl()
        }
    }
    
    private func stopImpl() {
        state = .hidden
        currentPlan = nil
        current = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
