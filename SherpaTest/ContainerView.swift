//
//  ContainerView.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

struct SkipButton: View {
    @EnvironmentObject var sherpa: SherpaGuide
    
    var body: some View {
        Button(action: quit) {
            Text("Skip")
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white).shadow(radius: 1))
        }
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    func quit() {
        withAnimation {
            sherpa.stop()
        }
    }
}

struct SherpaContainerView<Content: View>: View {
    @StateObject private var guide = SherpaGuide()
    
    let content: Content
    let accessory: AnyView
    
    @State private var popoverSize: CGSize = .zero
    
    init<Accessory: View>(accessory: Accessory, @ViewBuilder content: () -> Content) {
        self.accessory = AnyView(accessory)
        self.content = content()
    }
    
    init(@ViewBuilder content: () -> Content) {
        self.init(accessory: EmptyView(), content: content)
    }
    
    func currentDetails(from all: SherpaPreferenceKey.Value) -> SherpaDetails? {
        if let current = guide.current, let details = all[current.key()] {
            return details
        } else {
            return nil
        }
    }
    
    var colorOverlay: some View {
        Color(white: 0.8, opacity: 0.4)
    }
    
    var body: some View {
        content
            .environmentObject(guide)
            .overlayPreferenceValue(SherpaPreferenceKey.self, { all in
                ZStack {
                    if guide.state == .transition {
                        colorOverlay
                            .edgesIgnoringSafeArea(.all)
                        if let details = currentDetails(from: all) {
                            Callout(config: details.config, onTap: {}).opacity(0)
                        }
                    } else if guide.state == .active {
                        if let current = guide.current, let details = currentDetails(from: all) {
                            GeometryReader { proxy in
                                ForEach(overlayFrames(for: proxy[details.anchor], screen: proxy.size)) { frame in
                                    colorOverlay
                                        .frame(width: frame.rect.width, height: frame.rect.height)
                                        .offset(x: frame.rect.minX, y: frame.rect.minY)
                                }
                                .onTapGesture {
                                    current.onBackgroundTap(sherpa: guide)
                                }
                                
                                if !details.config.passthroughTouches {
                                    Color.black.opacity(0.05)
                                        .frame(width: proxy[details.anchor].width, height: proxy[details.anchor].height)
                                        .offset(x: proxy[details.anchor].minX, y: proxy[details.anchor].minY)
                                        .onTapGesture {
                                            current.onBackgroundTap(sherpa: guide)
                                        }
                                }
                                
                                Callout(config: details.config, onTap: {
                                    current.onExplanationTap(sherpa: guide)
                                })
                                .offset(
                                    x: proxy[details.anchor].midX - popoverSize.width / 2,
                                    y: details.config.direction == .up ? proxy[details.anchor].minY - popoverSize.height : proxy[details.anchor].maxY
                                )
                            }.edgesIgnoringSafeArea(.all)
                        } else {
                            failed(active: guide.current?.key())
                        }
                    }
                    if guide.state != .hidden {
                        accessory.environmentObject(guide)
                    }
                }
            })
            .onPreferenceChange(CalloutPreferenceKey.self, perform: { popoverSize = $0 })
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

struct SherpaDetails {
    let anchor: Anchor<CGRect>
    let config: CalloutConfig
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
