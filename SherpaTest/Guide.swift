//
//  Guide.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

extension View {
    func guide<Plan>(isActive: Bool, plan: Plan.Type) -> some View where Plan: SherpaPlan {
        GuidableView(isActive: isActive, plan: plan) {
            self
        }
    }

    func sherpaMark<T: SherpaPlan>(_ name: T) -> some View {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            return [name.key(): SherpaDetails(anchor: anchor, config: name.config())]
        })
    }
    
    func sherpaExternalMark<T: SherpaPlan>(_ name: T, edge: Edge, size: CGFloat = 100) -> some View {
        let width: CGFloat? = (edge == .leading || edge == .trailing) ? size : nil
        let height: CGFloat? = (edge == .top || edge == .bottom) ? size : nil
        
        let alignment: Alignment
        switch edge {
        case .top: alignment = .top
        case .leading: alignment = .leading
        case .trailing: alignment = .trailing
        case .bottom: alignment = .bottom
        }
        
        return overlay(Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).frame(width: width, height: height).sherpaMark(name).padding(Edge.Set(edge), -size), alignment: alignment)
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


struct GuidableView<Content: View, Plan: SherpaPlan>: View {
    let isActive: Bool
    let content: Content
    
    @EnvironmentObject private var sherpa: SherpaGuide
    
    init(isActive: Bool, plan: Plan.Type, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.content = content()
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
    func config() -> CalloutConfig
}
