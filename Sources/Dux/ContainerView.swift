//
//  ContainerView.swift
//  Dux
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

public struct SkipButton: View {
    @EnvironmentObject var dux: Dux
    
    public var body: some View {
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
            dux.stop()
        }
    }
}

public struct DuxContainerView<Content: View>: View {
    @StateObject private var guide = Dux()
    
    let content: Content
    let accessory: AnyView
    
    @State private var popoverSize: CGSize = .zero
    
    public init<Accessory: View>(accessory: Accessory, @ViewBuilder content: () -> Content) {
        self.accessory = AnyView(accessory)
        self.content = content()
    }
    
    public init(@ViewBuilder content: () -> Content) {
        self.init(accessory: EmptyView(), content: content)
    }
    
    public var body: some View {
        content
            .environmentObject(guide)
            .overlayPreferenceValue(DuxTagPreferenceKey.self, { all in
                DuxOverlay(guide: guide, accessory: accessory, allRecordedItems: all, popoverSize: popoverSize, duxState: guide.statePublisher)
            })
            .onPreferenceChange(CalloutPreferenceKey.self, perform: { popoverSize = $0 })
    }
}

struct DuxOverlay: View {
    let guide: Dux
    let accessory: AnyView
    let allRecordedItems: DuxTagPreferenceKey.Value
    let popoverSize: CGSize

    @ObservedObject var duxState: DuxStatePublisher
    
    var body: some View {
        ZStack {
            if duxState.state == .transition {
                Color(white: 0.8, opacity: 0.4)
                    .edgesIgnoringSafeArea(.all)
                if let current = guide.current, let details = allRecordedItems[current] {
                    details.callout.createView(onTap: {}).opacity(0)
                }
            } else if duxState.state == .active {
                if let current = guide.current,  let tagInfo = allRecordedItems[current] {
                    ActiveDuxOverlay(tagInfo: tagInfo, guide: guide, popoverSize: popoverSize)
                }
            }
            if duxState.state != .hidden {
                accessory.environmentObject(guide)
            }
        }
    }
}

struct ActiveDuxOverlay: View {
    let tagInfo: DuxTagInfo
    let guide: Dux
    let popoverSize: CGSize
    
    func offsetX(cutout: CGRect) -> CGFloat {
        switch tagInfo.callout.edge {
        case .top, .bottom:
            return cutout.midX - popoverSize.width / 2
        case .leading:
            return cutout.minX - popoverSize.width
        case .trailing:
            return cutout.maxX
        }
    }
    
    func offsetY(cutout: CGRect) -> CGFloat {
        switch tagInfo.callout.edge {
        case .leading, .trailing:
            return cutout.midY - popoverSize.height / 2
        case .top:
            return cutout.minY - popoverSize.height
        case .bottom:
            return cutout.maxY
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            CutoutOverlay(cutoutFrame: proxy[tagInfo.anchor], screenSize: proxy.size)
                .onTapGesture {
                    guide.advance()
                }

            touchModeView(for: proxy[tagInfo.anchor], mode: tagInfo.touchMode)

            tagInfo.callout.createView(onTap: guide.advance)
                .offset(
                    x: offsetX(cutout: proxy[tagInfo.anchor]),
                    y: offsetY(cutout: proxy[tagInfo.anchor])
                )
        }.edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    func touchModeView(for cutout: CGRect, mode: CutoutTouchMode) -> some View {
        switch mode {
        case .passthrough: EmptyView()
        case .advance:
            Color.black.opacity(0.05)
                .frame(width: cutout.width, height: cutout.height)
                .offset(x: cutout.minX, y: cutout.minY)
                .onTapGesture {
                    guide.advance()
                }
        case .custom(let action):
            Color.black.opacity(0.05)
                .frame(width: cutout.width, height: cutout.height)
                .offset(x: cutout.minX, y: cutout.minY)
                .onTapGesture {
                    action()
                }
        }
    }
}

struct CutoutOverlay: View {
    let cutoutFrame: CGRect
    let screenSize: CGSize
    
    var overlayFrames: [OverlayFrame] {
        return [
            .init(rect: .init(x: 0, y: 0, width: cutoutFrame.minX, height: screenSize.height)),
            .init(rect: .init(x: cutoutFrame.maxX, y: 0, width: screenSize.width - cutoutFrame.maxX, height: screenSize.height)),
            .init(rect: .init(x: cutoutFrame.minX, y: 0, width: cutoutFrame.width, height: cutoutFrame.minY)),
            .init(rect: .init(x: cutoutFrame.minX, y: cutoutFrame.maxY, width: cutoutFrame.width, height: screenSize.height - cutoutFrame.maxY))
        ]
    }
    
    var body: some View {
        ForEach(overlayFrames) { frame in
            Color(white: 0.8, opacity: 0.4)
                .frame(width: frame.rect.width, height: frame.rect.height)
                .offset(x: frame.rect.minX, y: frame.rect.minY)
        }
    }
}

struct OverlayFrame: Identifiable {
    let rect: CGRect
    
    var id: String {
        rect.debugDescription
    }
}

struct DuxTagInfo {
    let anchor: Anchor<CGRect>
    let callout: Callout
    let touchMode: CutoutTouchMode
}

struct DuxTagPreferenceKey: PreferenceKey {
    typealias Value = [String: DuxTagInfo]
    
    static var defaultValue: Value = [:]
    
    static func reduce(value acc: inout Value, nextValue: () -> Value) {
        let newValue = nextValue()
        for (key, value) in newValue {
            acc[key] = value
        }
    }
}
