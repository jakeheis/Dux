//
//  ManualDemo.swift
//  Example
//
//  Created by Jake Heiser on 9/22/21.
//

import Dux
import SwiftUI

struct ManualDemo: View {
    enum Tags: DuxTags {
        case choice
        case left
        case right
        case final
        
        func makeCallout() -> Callout {
            switch self {
            case .choice: return .text("Choose left or right")
            case .left: return .okText("You chose left", edge: .trailing)
            case .right: return .okText("You chose right", edge: .leading)
            case .final: return .okText("But both end here")
            }
        }
    }
    
    @EnvironmentObject var dux: Dux
    
    var body: some View {
        VStack {
            Button(action: startTapped) {
                Text("Start")
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.blue))
            }
            
            HStack {
                Button(action: { dux.jump(to: Tags.left) }) {
                    Text("Go left")
                }
                Spacer()
                Button(action: { dux.jump(to: Tags.right) }) {
                    Text("Go Right")
                }
            }.padding()
            .duxTag(Tags.choice)
            
            HStack {
                Text("Left")
                    .duxTag(Tags.left)
                Spacer()
                Text("Right")
                    .duxTag(Tags.right)
            }.padding()
            
            Text("End here")
                .duxTag(Tags.final)
        }
    }
    
    func startTapped() {
        dux.start(tags: Tags.self, delegate: self)
    }
}

extension ManualDemo: DuxDelegate {
    func cutoutTouchMode(dux: Dux) -> CutoutTouchMode {
        switch dux.matchCurrent(Tags.self) {
        case .choice: return .passthrough
        default: return .custom { handleTap(tag: dux.matchCurrent(Tags.self)) }
        }
    }
    
    func onBackgroundTap(dux: Dux) {
        handleTap(tag: dux.matchCurrent(Tags.self))
    }
    
    func onCalloutTap(dux: Dux) {
        handleTap(tag: dux.matchCurrent(Tags.self))
    }
    
    private func handleTap(tag: Tags?) {
        switch dux.matchCurrent(Tags.self) {
        case .left, .right: dux.jump(to: Tags.final)
        case .final: dux.advance()
        default: break
        }
    }
}
