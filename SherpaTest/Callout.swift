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

struct CalloutConfig {
    enum Direction {
        case up
        case down
    }
    
    static func text(_ text: String, direction: Direction = .up, passthroughTouches: Bool = true) -> Self {
        .view(direction: direction, passthroughTouches: passthroughTouches) { Text(text) }
    }
    
    static func view<V: View>(direction: Direction = .up, passthroughTouches: Bool = true, @ViewBuilder content: () -> V) -> Self {
        let inside = content()
        let bodyBlock: (@escaping () -> Void) -> AnyView = { onTap in
            AnyView(Button(action: onTap) {
                inside
            }
            .buttonStyle(CalloutButtonStyle(direction: direction)))
        }
        
        return .init(body: bodyBlock, direction: direction, passthroughTouches: passthroughTouches)
    }
    
    let body: (_ onTap: @escaping () -> Void) -> AnyView
    let direction: Direction
    let passthroughTouches: Bool
}

struct CalloutButtonStyle: ButtonStyle {
    let direction: CalloutConfig.Direction
    
    private func color(for configuration: Configuration) -> Color {
        configuration.isPressed ? Color(white: 0.8, opacity: 1.0) : Color.white
    }
    
    private func arrow(for configuration: Configuration) -> some View {
        Image(systemName: "triangle.fill")
            .resizable().aspectRatio(contentMode: .fit)
            .foregroundColor(color(for: configuration))
            .frame(width: 15)
            .shadow(radius: 1)
            .clipped()
    }
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            if direction == .down {
                arrow(for: configuration)
                    .offset(y: 3)
            }
            configuration.label
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color(for: configuration))
                        .shadow(radius: 1)
                )
            if direction == .up {
                arrow(for: configuration)
                    .rotationEffect(.degrees(180))
                    .offset(y: -3)
            }
        }
    }
}

struct CalloutPreferenceKey: PreferenceKey {
    typealias Value = CGSize

    static var defaultValue: Value = .zero
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
