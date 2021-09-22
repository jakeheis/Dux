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

    func sherpaMark<T: SherpaPlan>(_ name: T, touchMode: CutoutTouchMode = .advance) -> some View {
        anchorPreference(key: SherpaPreferenceKey.self, value: .bounds, transform: { anchor in
            return [name.key(): SherpaDetails(anchor: anchor, config: name.config(), touchMode: touchMode)]
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
    private(set) var current: String? = nil

    private var currentPlan: [String]?
    
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
    
    func start<Plan: SherpaPlan>(plan: Plan.Type, after interval: TimeInterval = 0.5) {
        let plan = plan.allCases.map { $0.key() }
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
                    sherpa.start(plan: Plan.self)
                }
            }
    }
}

protocol SherpaPlan: CaseIterable {
    func config() -> CalloutConfig
}

extension SherpaPlan {
    func key() -> String {
        String(reflecting: Self.self) + "." + String(describing: self)
    }
}
