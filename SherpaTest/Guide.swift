//
//  Guide.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

extension View {
    func guide<Tags: SherpaTags>(isActive: Bool, tags: Tags.Type) -> some View {
        GuidableView(isActive: isActive, tags: tags) {
            self
        }
    }

    func sherpaTag<T: SherpaTags>(_ tag: T, touchMode: CutoutTouchMode = .advance) -> some View {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            return [tag.key(): SherpaDetails(anchor: anchor, callout: tag.createCallout(), touchMode: touchMode)]
        })
    }
    
    func sherpaExtensionTag<T: SherpaTags>(_ tag: T, touchMode: CutoutTouchMode = .advance, edge: Edge, size: CGFloat = 100) -> some View {
        let width: CGFloat? = (edge == .leading || edge == .trailing) ? size : nil
        let height: CGFloat? = (edge == .top || edge == .bottom) ? size : nil
        
        let alignment: Alignment
        switch edge {
        case .top: alignment = .top
        case .leading: alignment = .leading
        case .trailing: alignment = .trailing
        case .bottom: alignment = .bottom
        }
        
        return overlay(Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).frame(width: width, height: height).sherpaTag(tag, touchMode: touchMode).padding(Edge.Set(edge), -size), alignment: alignment)
    }
    
    func stopSherpa(_ sherpa: SherpaGuide, onLink navigationLink: Bool) -> some View {
        onChange(of: navigationLink, perform: { shown in
            if shown {
                sherpa.stop()
            }
        })
    }
    
    func stopSherpa<V: Hashable>(_ sherpa: SherpaGuide, onTag navigationTag: V, selection: V) -> some View {
        onChange(of: selection, perform: { value in
            if navigationTag == value {
                sherpa.stop()
            }
        })
    }
}

class SherpaPublisher: ObservableObject {
    enum State {
        case hidden
        case transition
        case active
    }
    
    @Published var state: State = .hidden
}

final class SherpaGuide: ObservableObject {
    let publisher = SherpaPublisher()
    private(set) var current: String? = nil

    private var currentPlan: [String]?
    
    func start<Tags: SherpaTags>(tags: Tags.Type) {
        let plan = tags.allCases.map { $0.key() }
        currentPlan = plan
        
        if plan.count > 0 {
            moveTo(item: plan[0])
            current = plan[0]
        }
    }
    
    func advance() {
        guard let current = current, let currentPlan = currentPlan else {
            return
        }
        guard let index = currentPlan.firstIndex(of: current) else {
            return
        }
        
        guard index + 1 < currentPlan.count else {
            stop()
            return
        }
        
        moveTo(item: currentPlan[index + 1])
    }
    
    func jump<T: SherpaTags>(to tag: T) {
        guard let currentPlan = currentPlan, let index = currentPlan.firstIndex(of: tag.key()) else {
            return
        }
        moveTo(item: currentPlan[index])
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
    
    private func moveTo(item: String) {
        self.current = item
        
        withAnimation {
            if publisher.state == .active {
                self.publisher.state = .transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.publisher.state = .active
                    }
                }
            } else {
                self.publisher.state = .active
            }
        }
    }
    
    private func stopImpl() {
        publisher.state = .hidden
        currentPlan = nil
        current = nil
    }
}


struct GuidableView<Content: View, Tags: SherpaTags>: View {
    let isActive: Bool
    let content: Content
    let startDelay: TimeInterval
    
    @EnvironmentObject private var sherpa: SherpaGuide
    
    init(isActive: Bool, tags: Tags.Type, startDelay: TimeInterval = 0.5, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.content = content()
        self.startDelay = startDelay
    }
    
    var body: some View {
        content
            .onAppear {
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        sherpa.start(tags: Tags.self)
                    }
                }
            }
            .onDisappear {
                sherpa.stop()
            }
    }
}

protocol SherpaTags: CaseIterable {
    func createCallout() -> Callout
}

extension SherpaTags {
    func key() -> String {
        String(reflecting: Self.self) + "." + String(describing: self)
    }
}
