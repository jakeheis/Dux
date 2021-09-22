//
//  ContainerView.swift
//  Dux
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

public struct DuxContainerView<Content: View>: View {
    @StateObject private var dux = Dux()
    
    let content: Content
    
    @State private var popoverSize: CGSize = .zero
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(dux)
            .overlayPreferenceValue(DuxTagPreferenceKey.self, { all in
                DuxOverlay(dux: dux, allRecordedItems: all, popoverSize: popoverSize, duxState: dux.statePublisher)
            })
            .onPreferenceChange(CalloutPreferenceKey.self, perform: { popoverSize = $0 })
    }
}

public struct SkipButton: View {
    @EnvironmentObject var dux: Dux
    
    public init() {}
    
    public var body: some View {
        Button(action: quit) {
            Text("Skip")
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white).shadow(radius: 1))
        }
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
    
    private func quit() {
        withAnimation {
            dux.stop()
        }
    }
}

private struct DuxOverlay: View {
    let dux: Dux
    let allRecordedItems: DuxTagPreferenceKey.Value
    let popoverSize: CGSize

    @ObservedObject var duxState: DuxStatePublisher
    
    var body: some View {
        ZStack {
            if duxState.state == .transition {
                dux.delegate.overlay(dux: dux)
                    .edgesIgnoringSafeArea(.all)
                if let current = dux.current, let details = allRecordedItems[current] {
                    details.callout.createView(onTap: {}).opacity(0)
                }
            } else if duxState.state == .active {
                if let current = dux.current,  let tagInfo = allRecordedItems[current] {
                    ActiveDuxOverlay(tagInfo: tagInfo, dux: dux, popoverSize: popoverSize)
                }
            }
            if duxState.state != .hidden {
                dux.delegate.accessoryView(dux: dux).environmentObject(dux)
            }
        }
    }
}

private struct ActiveDuxOverlay: View {
    let tagInfo: DuxTagInfo
    let dux: Dux
    let popoverSize: CGSize
    
    var body: some View {
        GeometryReader { proxy in
            cutoutTint(for: proxy[tagInfo.anchor], screenSize: proxy.size)
                .onTapGesture {
                    dux.delegate.onBackgroundTap(dux: dux)
                }

            touchModeView(for: proxy[tagInfo.anchor], mode: dux.delegate.cutoutTouchMode(dux: dux))

            tagInfo.callout.createView(onTap: { dux.delegate.onCalloutTap(dux: dux) })
                .offset(
                    x: cutoutOffsetX(cutout: proxy[tagInfo.anchor]),
                    y: cutoutOffsetY(cutout: proxy[tagInfo.anchor])
                )
        }.edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    private func cutoutTint(for cutoutFrame: CGRect, screenSize: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            if cutoutFrame.minX > 0 {
                dux.delegate.overlay(dux: dux)
                    .frame(width: cutoutFrame.minX, height: screenSize.height)
            }
            if cutoutFrame.maxX < screenSize.width {
                dux.delegate.overlay(dux: dux)
                    .frame(width: screenSize.width - cutoutFrame.maxX, height: screenSize.height)
                    .offset(x: cutoutFrame.maxX)
            }
            if cutoutFrame.minY > 0 {
                dux.delegate.overlay(dux: dux)
                    .frame(width: cutoutFrame.width, height: cutoutFrame.minY)
                    .offset(x: cutoutFrame.minX)
            }
            if cutoutFrame.maxY < screenSize.height {
                dux.delegate.overlay(dux: dux)
                    .frame(width: cutoutFrame.width, height: screenSize.height - cutoutFrame.maxY)
                    .offset(x: cutoutFrame.minX, y: cutoutFrame.maxY)
            }
        }
    }
    
    @ViewBuilder
    private func touchModeView(for cutout: CGRect, mode: CutoutTouchMode) -> some View {
        switch mode {
        case .passthrough: EmptyView()
        case .advance:
            Color.black.opacity(0.05)
                .frame(width: cutout.width, height: cutout.height)
                .offset(x: cutout.minX, y: cutout.minY)
                .onTapGesture {
                    dux.advance()
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
    
    private func cutoutOffsetX(cutout: CGRect) -> CGFloat {
        switch tagInfo.callout.edge {
        case .top, .bottom:
            return cutout.midX - popoverSize.width / 2
        case .leading:
            return cutout.minX - popoverSize.width
        case .trailing:
            return cutout.maxX
        }
    }
    
    private func cutoutOffsetY(cutout: CGRect) -> CGFloat {
        switch tagInfo.callout.edge {
        case .leading, .trailing:
            return cutout.midY - popoverSize.height / 2
        case .top:
            return cutout.minY - popoverSize.height
        case .bottom:
            return cutout.maxY
        }
    }
}

public struct GuidableView<Content: View, Tags: DuxTags>: View {
    let isActive: Bool
    let delegate: DuxDelegate?
    let startDelay: TimeInterval
    let content: Content

    @EnvironmentObject private var dux: Dux
    
    init(isActive: Bool, tags: Tags.Type, delegate: DuxDelegate?, startDelay: TimeInterval = 0.5, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.delegate = delegate
        self.startDelay = startDelay
        self.content = content()
    }
    
    public var body: some View {
        content
            .onAppear {
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        dux.start(tags: Tags.self, delegate: delegate)
                    }
                }
            }
            .onDisappear {
                dux.stop()
            }
            .onChange(of: isActive) { active in
                if active {
                    dux.start(tags: Tags.self, delegate: delegate)
                }
            }
    }
}

struct DuxTagInfo {
    let anchor: Anchor<CGRect>
    let callout: Callout
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
