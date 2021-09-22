//
//  Dux.swift
//  Dux
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

public protocol DuxDelegate {
    func cutoutTouchMode(dux: Dux) -> CutoutTouchMode
    func onBackgroundTap(dux: Dux)
    func onCalloutTap(dux: Dux)
}

extension DuxDelegate {
    func cutoutTouchMode(dux: Dux) -> CutoutTouchMode {
        .advance
    }
    
    func onBackgroundTap(dux: Dux) {
        dux.advance()
    }
    
    func onCalloutTap(dux: Dux) {
        dux.advance()
    }
}

struct DefaultDuxDelegate: DuxDelegate {}

public final class Dux: ObservableObject {
    let statePublisher = DuxStatePublisher()
    public private(set) var current: String? = nil

    private var currentPlan: [String]?
    
    var delegate: DuxDelegate = DefaultDuxDelegate()
    
    public func start<Tags: DuxTags>(tags: Tags.Type, delegate: DuxDelegate?) {
        let plan = tags.allCases.map { $0.key() }
        currentPlan = plan
        self.delegate = delegate ?? DefaultDuxDelegate()
        
        if plan.count > 0 {
            moveTo(item: plan[0])
            current = plan[0]
        }
    }
    
    func matchCurrent<T: DuxTags>(_ tags: T.Type) -> T? {
        T.allCases.first(where: { $0.key() == current })
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
        withAnimation {
            if statePublisher.state == .active {
                statePublisher.state = .transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.current = item
                    self.statePublisher.state = .transition
                    DispatchQueue.main.async {
                        withAnimation {
                            self.statePublisher.state = .active
                        }
                    }
                }
            } else {
                current = item
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

class DuxStatePublisher: ObservableObject {
    enum State {
        case hidden
        case transition
        case active
    }
    
    @Published var state: State = .hidden
}

public protocol DuxTags: CaseIterable {
    func createCallout() -> Callout
}

extension DuxTags {
    func key() -> String {
        String(reflecting: Self.self) + "." + String(describing: self)
    }
}
