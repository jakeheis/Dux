//
//  DemoList.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

struct DemoListView: View {
    var body: some View {
        TabView {
            NavigationView {
                List {
                    NavigationLink(destination: DefaultDemo()) {
                        Text("Default")
                    }
                }
            }.tabItem { Text("SUP") }
        }
    }
}

struct DemoView: View {
    private let spacing: CGFloat = 10
    
    static var currentDemo: ((Plan) -> CalloutConfig)?
    
    enum Plan: SherpaPlan {
        case bar
        case name
        case email
        
        func config() -> CalloutConfig {
            if let currentDemo = currentDemo {
                return currentDemo(self)
            } else {
                return .text("Demo")
            }
        }
    }
    
    init(demo: @escaping (Plan) -> CalloutConfig) {
        Self.currentDemo = demo
    }
    
    var body: some View {
        VStack {
            Text("HEY")
            Image(systemName: "person.crop.circle.fill")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 100)
            Text("@jakeheis")
                .sherpaMark(Plan.name)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(overlay, alignment: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .sherpaExternalMark(Plan.bar, edge: .top)
        .guide(isActive: true, plan: Plan.self)
    }
    
    var overlay: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                HStack(spacing: spacing) {
                    GreenText(text: "34 posts", width: proxy.size.width / 4 - spacing * 2 / 3)
                    GreenText(text: "me@me.com", width: proxy.size.width / 2 - spacing * 2 / 3)
                        .sherpaMark(Plan.email)
                    GreenText(text: "29 karma", width: proxy.size.width / 4 - spacing * 2 / 3)
                }
            }
        }.padding()
    }
}

struct GreenText: View {
    let text: String
    let width: CGFloat
    
    var body: some View {
        Text(text)
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(.horizontal)
            .frame(width: width, height: 60)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.green))
    }
}

struct DemoViewPreview: PreviewProvider {
    static var previews: some View {
        SherpaContainerView {
            NavigationView {
                DefaultDemo()
            }
        }
    }
}

struct DefaultDemo: View {
    var body: some View {
        DemoView(demo: defaultDemo)
            .navigationTitle("Default")
    }
    
    func defaultDemo(plan: DemoView.Plan) -> CalloutConfig {
        switch plan {
        case .bar: return .text("You are in the profile section, where you can review all info.", direction: .down)
        case .name: return .text("That, here, is your name.")
        case .email: return .text("That is your email address")
        }
    }
}
