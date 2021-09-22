//
//  Callout.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

struct Callout: View {
    let config: CalloutConfig
    let onTap: () -> Void
    
    var body: some View {
        config.body(onTap)
            .overlay(GeometryReader { proxy in
                Color.clear
                    .preference(key: CalloutPreferenceKey.self, value: proxy.size)
            })
    }
}

enum CutoutTouchMode {
    case passthrough
    case advance
    case custom(() -> Void)
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
        let inside = content()
        let bodyBlock: (@escaping () -> Void) -> AnyView = { onTap in
            AnyView(Button(action: onTap) {
                inside
            }
            .buttonStyle(CalloutButtonStyle(direction: direction)))
        }
        
        return .init(body: bodyBlock, direction: direction)
    }
    
    let body: (_ onTap: @escaping () -> Void) -> AnyView
    let direction: Direction
}

struct CalloutBubble: Shape {
    let direction: CalloutConfig.Direction
    
    func path(in rect: CGRect) -> Path {
        let pointerWidth: CGFloat = 10
        let pointerHeight: CGFloat = 10
        
        var path = Path()
        
        let points: [CGPoint]
        let frame: CGRect
        switch direction {
        case .down:
            points = [
                .init(x: rect.width / 2 - pointerWidth / 2, y: pointerHeight),
                .init(x: rect.width / 2 + pointerWidth / 2, y: pointerHeight),
                .init(x: rect.width / 2, y: 0)
            ]
            frame = .init(x: 0, y: pointerHeight, width: rect.width, height: rect.height - pointerHeight)
        case .up:
            points = [
                .init(x: rect.width / 2 - pointerWidth / 2, y: rect.height - pointerHeight),
                .init(x: rect.width / 2 + pointerWidth / 2, y: rect.height - pointerHeight),
                .init(x: rect.width / 2, y: rect.height)
            ]
            frame = .init(x: 0, y: 0, width: rect.width, height: rect.height - pointerHeight)
        }
        
        path.move(to: points.last!)
        path.addLines(points)
        path.addRoundedRect(in: frame, cornerSize: .init(width: 5, height: 5))
        return path
    }
}

//struct CalloutBubblePreview: PreviewProvider {
//    static var previews: some View {
//        VStack {
//            CalloutBubble(direction: .down).fill(Color.green).shadow(radius: 1).frame(width: 100, height: 50)
//            CalloutBubble(direction: .up).fill(Color.green).shadow(radius: 1).frame(width: 100, height: 50)
//        }
//    }
//}

struct CalloutButtonStyle: ButtonStyle {
    let direction: CalloutConfig.Direction
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            if direction == .down {
                Color.clear.frame(width: 1, height: 10)
            }
            
            configuration.label
                .padding(6)
            
            if direction == .up {
                Color.clear.frame(width: 1, height: 10)
            }
        }.background(
            CalloutBubble(direction: direction)
                .fill(configuration.isPressed ? Color(white: 0.8, opacity: 1.0) : Color.white)
                .shadow(radius: 2)
        )
    }
}

struct CalloutPreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: Value = .zero
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
