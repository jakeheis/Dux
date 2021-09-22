//
//  CustomDemo.swift
//  Example
//
//  Created by Jake Heiser on 9/22/21.
//

import Dux
import SwiftUI

struct CustomDemo: View {
    enum Tags: DuxTags {
        case profilePicture
        case name
        case username
        
        func makeCallout() -> Callout {
            switch self {
            case .profilePicture: return .bubble {
                Label("This is custom content, but still in the default bubble", systemImage: "star")
            }
            case .name: return .text("Off the\nleading\nedge", edge: .leading)
            case .username: return .custom(edge: .top) { _ in
                    Text("Totally custom, no bubble")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 5).stroke(Color.green, lineWidth: 2))
                        .padding(.bottom)
                }
            }
        }
    }
        
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "person.crop.circle.fill")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 100)
                .duxTag(Tags.profilePicture)
            Text("John Smith")
                .duxTag(Tags.name)
            Spacer()
            HStack(spacing: 10) {
                ProfileDetail(text: "34 posts")
                ProfileDetail(text: "@jsmith")
                    .duxTag(Tags.username)
                ProfileDetail(text: "29 karma")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .dux(isActive: true, tags: Tags.self, delegate: self)
    }
}

extension CustomDemo: DuxDelegate {
    func accessoryView(dux: Dux) -> AnyView? {
        AnyView(CustomQuitButton())
    }
    
    func overlay(dux: Dux) -> AnyView? {
        AnyView(Color.red.opacity(0.8))
    }
}

public struct CustomQuitButton: View {
    @EnvironmentObject var dux: Dux
    
    public init() {}
    
    public var body: some View {
        Button(action: quit) {
            Text("Quit walkthrough")
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 70)
        }
        .background(RoundedRectangle(cornerRadius: 5).fill(Color.yellow))
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func quit() {
        withAnimation {
            dux.stop()
        }
    }
}
