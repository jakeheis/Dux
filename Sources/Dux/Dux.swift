//
//  Dux.swift
//  Dux
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

class DuxStatePublisher: ObservableObject {
    enum State {
        case hidden
        case transition
        case active
    }
    
    @Published var state: State = .hidden
}

public final class Dux: ObservableObject {
    let statePublisher = DuxStatePublisher()
    private(set) var current: String? = nil

    private var currentPlan: [String]?
    
    public func start<Tags: DuxTags>(tags: Tags.Type) {
        let plan = tags.allCases.map { $0.key() }
        currentPlan = plan
        
        if plan.count > 0 {
            moveTo(item: plan[0])
            current = plan[0]
        }
    }
    
    public func advance() {
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
    
    public func jump<T: DuxTags>(to tag: T) {
        guard let currentPlan = currentPlan, let index = currentPlan.firstIndex(of: tag.key()) else {
            return
        }
        moveTo(item: currentPlan[index])
    }

    public func stop(animated: Bool = true) {
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
            if statePublisher.state == .active {
                statePublisher.state = .transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        self.statePublisher.state = .active
                    }
                }
            } else {
                statePublisher.state = .active
            }
        }
    }
    
    private func stopImpl() {
        statePublisher.state = .hidden
        currentPlan = nil
        current = nil
    }
}


public struct GuidableView<Content: View, Tags: DuxTags>: View {
    let isActive: Bool
    let content: Content
    let startDelay: TimeInterval
    
    @EnvironmentObject private var dux: Dux
    
    init(isActive: Bool, tags: Tags.Type, startDelay: TimeInterval = 0.5, @ViewBuilder content: () -> Content) {
        self.isActive = isActive
        self.content = content()
        self.startDelay = startDelay
    }
    
    public var body: some View {
        content
            .onAppear {
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                        dux.start(tags: Tags.self)
                    }
                }
            }
            .onDisappear {
                dux.stop()
            }
    }
}

public protocol DuxTags: CaseIterable {
    func createCallout() -> Callout
}

extension DuxTags {
    func key() -> String {
        String(reflecting: Self.self) + "." + String(describing: self)
    }
}
