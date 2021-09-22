//
//  DemoList.swift
//  SherpaTest
//
//  Created by Jake Heiser on 9/21/21.
//

import SwiftUI

struct DemoListView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DefaultDemo()) {
                    Text("Default")
                }
                NavigationLink(destination: HintOnlyDemo()) {
                    Text("Hint only")
                }
                NavigationLink(destination: CustomDemo()) {
                    Text("Custom")
                }
            }
        }.tabItem { Text("SUP") }
    }
}

struct DemoView: View {
    private let spacing: CGFloat = 10
    
    static var currentDemo: ((Tags) -> Callout)?
    
    enum Tags: SherpaTags {
        case bar
        case name
        case email
        
        func createCallout() -> Callout {
            if let currentDemo = currentDemo {
                return currentDemo(self)
            } else {
                return .text("Demo")
            }
        }
    }
    
    init(demo: @escaping (Tags) -> Callout) {
        Self.currentDemo = { tags in demo(tags) }
    }
    
    var body: some View {
        VStack {
            Text("HEY")
            Image(systemName: "person.crop.circle.fill")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 100)
            Text("@jakeheis")
                .sherpaTag(Tags.name)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(overlay, alignment: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .sherpaExtensionTag(Tags.bar, touchMode: .passthrough, edge: .top)
        .guide(isActive: true, tags: Tags.self)
    }
    
    var overlay: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                HStack(spacing: spacing) {
                    GreenText(text: "34 posts", width: proxy.size.width / 4 - spacing * 2 / 3)
                    GreenText(text: "me@me.com", width: proxy.size.width / 2 - spacing * 2 / 3)
                        .sherpaTag(Tags.email)
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
                CustomDemo()
            }
        }
    }
}

struct DefaultDemo: View {
    var body: some View {
        DemoView(demo: demo)
            .navigationTitle("Default")
    }
    
    func demo(plan: DemoView.Tags) -> Callout {
        switch plan {
        case .bar: return .okText("You are in the profile section, where you can review all info.", edge: .bottom)
        case .name: return .okText("That, here, is your name.")
        case .email: return .okText("That is your email address")
        }
    }
}

struct HintOnlyDemo: View {
    var body: some View {
        DemoView(demo: demo)
            .navigationTitle("Hint only")
    }
    
    func demo(plan: DemoView.Tags) -> Callout {
        switch plan {
        case .bar: return .text("You are in the profile section, where you can review all info.", edge: .bottom)
        case .name: return .text("That, here, is your name.")
        case .email: return .text("That is your email address")
        }
    }
}

struct CustomDemo: View {
    var body: some View {
        DemoView(demo: demo)
            .navigationTitle("Custom")
    }
    
    func demo(plan: DemoView.Tags) -> Callout {
        switch plan {
        case .bar: return .custom(edge: .bottom) { onTap in
            CustomBubble(text: "You are in the profile section, where you can review all info.", onTap: onTap)
        }
        case .name: return .custom(edge: .bottom) { onTap in
            CustomBubble(text: "That, here, is your name.", onTap: onTap)
        }
        case .email: return .text("Email!", edge: .trailing)
        }
    }
    
    struct CustomBubble: View {
        let text: String
        let onTap: () -> Void
        
        var body: some View {
            VStack {
                Image(systemName: "arrow.up")
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 30)
                    .padding()
                HStack {
                    Text(text)
                    Button(action: onTap) {
                        Text("Ok!")
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.blue))
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white))
            }
        }
    }
}



//struct
